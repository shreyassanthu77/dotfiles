/*
 * Minimal Compiler-Explorer-style assembly filter.
 *
 * Configurable; not tied to a particular language. Works best on LLVM/GAS
 * text asm (clang, rustc, zig -femit-asm, etc.).
 *
 * Build:  cc -O2 -o filter-asm filter-asm.c
 * Usage:  ./filter-asm [options] < input.s > output.s
 *         ./filter-asm [options] input.s [-o output.s]
 *
 * Default filters match CE defaults for text asm: directives, comments,
 * unused labels. Library-code filtering is opt-in (-L) and needs --user
 * path substrings to classify .file entries as "yours".
 */

#define _POSIX_C_SOURCE 200809L

#include <ctype.h>
#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_FILES 4096
#define MAX_USER_PATTERNS 64

typedef struct {
    bool directives;
    bool comments;
    bool labels;
    bool library;
    bool trim;
    bool keep_data;
    /* After seeing user .loc, keep following lines until .cfi_endproc/.section
     * (closer to CE). Default off = strict: only while current .loc is user. */
    bool library_sticky;
    const char *user_patterns[MAX_USER_PATTERNS];
    int n_user_patterns;
    const char *input_path;
    const char *output_path;
} Options;

typedef struct {
    char *path; /* "dir/name" or single path */
    bool is_user;
} FileInfo;

typedef struct {
    char **lines;
    size_t nlines;
    char *buf;
    size_t buflen;
} Document;

/* ---------- small helpers ---------- */

static void die(const char *msg) {
    fprintf(stderr, "filter-asm: %s\n", msg);
    exit(1);
}

static void die_errno(const char *msg) {
    fprintf(stderr, "filter-asm: %s: %s\n", msg, strerror(errno));
    exit(1);
}

static const char *skip_ws(const char *s) {
    while (*s == ' ' || *s == '\t') s++;
    return s;
}

static bool starts_with(const char *s, const char *pfx) {
    return strncmp(s, pfx, strlen(pfx)) == 0;
}

static bool str_contains(const char *hay, const char *needle) {
    return needle[0] == '\0' || strstr(hay, needle) != NULL;
}

/* CE-ish "main source" names when no --user given */
static bool is_default_main_source(const char *path) {
    if (strcmp(path, "<stdin>") == 0 || strcmp(path, "<source>") == 0 || strcmp(path, "-") == 0)
        return true;
    /* example.c / example.zig etc at end of path */
    const char *base = strrchr(path, '/');
    base = base ? base + 1 : path;
    return starts_with(base, "example.");
}

static bool path_is_user(const Options *opt, const char *path) {
    if (opt->n_user_patterns == 0)
        return is_default_main_source(path);
    for (int i = 0; i < opt->n_user_patterns; i++) {
        if (str_contains(path, opt->user_patterns[i]))
            return true;
    }
    return false;
}

/* ---------- string set (open addressing via linear scan; fine for label sets) ---------- */

static uint32_t fnv1a(const char *s, size_t n) {
    uint32_t h = 2166136261u;
    for (size_t i = 0; i < n; i++) {
        h ^= (unsigned char)s[i];
        h *= 16777619u;
    }
    return h;
}

/* Simple hash set of interned slices into the document (not owned). */
typedef struct {
    const char **keys;
    size_t *lens;
    size_t cap;
    size_t n;
} HashSet;

static void hashset_init(HashSet *h, size_t hint) {
    h->cap = 16;
    while (h->cap < hint * 2) h->cap *= 2;
    h->keys = calloc(h->cap, sizeof *h->keys);
    h->lens = calloc(h->cap, sizeof *h->lens);
    h->n = 0;
    if (!h->keys || !h->lens) die("out of memory");
}

static void hashset_free(HashSet *h) {
    free(h->keys);
    free(h->lens);
    h->keys = NULL;
    h->lens = NULL;
    h->cap = h->n = 0;
}

static void hashset_grow(HashSet *h) {
    size_t ocap = h->cap;
    const char **okeys = h->keys;
    size_t *olens = h->lens;
    h->cap *= 2;
    h->keys = calloc(h->cap, sizeof *h->keys);
    h->lens = calloc(h->cap, sizeof *h->lens);
    if (!h->keys || !h->lens) die("out of memory");
    h->n = 0;
    for (size_t i = 0; i < ocap; i++) {
        if (!okeys[i]) continue;
        /* reinsert */
        uint32_t hash = fnv1a(okeys[i], olens[i]);
        size_t slot = hash & (h->cap - 1);
        while (h->keys[slot]) slot = (slot + 1) & (h->cap - 1);
        h->keys[slot] = okeys[i];
        h->lens[slot] = olens[i];
        h->n++;
    }
    free(okeys);
    free(olens);
}

static bool hashset_has(const HashSet *h, const char *s, size_t n) {
    if (h->cap == 0) return false;
    uint32_t hash = fnv1a(s, n);
    size_t slot = hash & (h->cap - 1);
    while (h->keys[slot]) {
        if (h->lens[slot] == n && memcmp(h->keys[slot], s, n) == 0)
            return true;
        slot = (slot + 1) & (h->cap - 1);
    }
    return false;
}

static void hashset_add(HashSet *h, const char *s, size_t n) {
    if (h->cap == 0) hashset_init(h, 64);
    if ((h->n + 1) * 4 >= h->cap * 3) hashset_grow(h);
    uint32_t hash = fnv1a(s, n);
    size_t slot = hash & (h->cap - 1);
    while (h->keys[slot]) {
        if (h->lens[slot] == n && memcmp(h->keys[slot], s, n) == 0)
            return;
        slot = (slot + 1) & (h->cap - 1);
    }
    h->keys[slot] = s;
    h->lens[slot] = n;
    h->n++;
}

/* ---------- line classification ---------- */

static bool is_comment_only(const char *line) {
    const char *s = skip_ws(line);
    if (*s == '#' || *s == '@') return true;
    if (s[0] == '/' && s[1] == '/') return true;
    if (s[0] == '/' && s[1] == '*') return true;
    if (*s == ';') return true;
    return false;
}

static bool is_data_defn(const char *line) {
    const char *s = skip_ws(line);
    if (*s != '.') return false;
    static const char *kinds[] = {
        "ascii", "asciz", "string", "byte", "4byte", "8byte", "2byte", "1byte",
        "short", "word", "long", "quad", "zero", "space", "skip", "fill",
        "float", "double", "value", "hword", "xword", "octa", NULL
    };
    s++;
    for (int i = 0; kinds[i]; i++) {
        size_t n = strlen(kinds[i]);
        if (strncmp(s, kinds[i], n) == 0 && !isalnum((unsigned char)s[n]) && s[n] != '_')
            return true;
    }
    return false;
}

static bool is_directive(const char *line) {
    return *skip_ws(line) == '.';
}

/* label at start:  foo:  or "foo.bar": */
static bool match_label_def(const char *line, const char **name, size_t *namelen) {
    const char *s = skip_ws(line);
    const char *start = s;
    if (*s == '"') {
        s++;
        while (*s && *s != '"') s++;
        if (*s != '"') return false;
        s++;
        if (*s != ':') return false;
        *name = start;
        *namelen = (size_t)(s - start);
        return true;
    }
    if (!(isalnum((unsigned char)*s) || *s == '_' || *s == '.' || *s == '$' || *s == '@'))
        return false;
    while (isalnum((unsigned char)*s) || *s == '_' || *s == '.' || *s == '$' || *s == '@')
        s++;
    if (*s != ':') return false;
    /* whole-line label (ignore "1: instr" local labels with trailing code) */
    const char *rest = skip_ws(s + 1);
    if (*rest != '\0') return false;
    *name = start;
    *namelen = (size_t)(s - start);
    return true;
}

/* `sym = expr` linker/asm alias (not an instruction). */
static bool is_assignment(const char *line) {
    const char *s = skip_ws(line);
    if (*s == '"') {
        s++;
        while (*s && *s != '"') s++;
        if (*s != '"') return false;
        s++;
    } else if (isalnum((unsigned char)*s) || *s == '_' || *s == '.' || *s == '$' || *s == '@') {
        while (isalnum((unsigned char)*s) || *s == '_' || *s == '.' || *s == '$' || *s == '@')
            s++;
    } else {
        return false;
    }
    s = skip_ws(s);
    return *s == '=';
}

static bool has_opcode(const char *line) {
    const char *s = skip_ws(line);
    /* strip leading label on same line */
    if (*s == '"') {
        const char *p = s + 1;
        while (*p && *p != '"') p++;
        if (*p == '"' && p[1] == ':') s = skip_ws(p + 2);
    } else {
        const char *p = s;
        while (isalnum((unsigned char)*p) || *p == '_' || *p == '.' || *p == '$' || *p == '@')
            p++;
        if (*p == ':') s = skip_ws(p + 1);
    }
    /* strip comments */
    const char *code_end = s;
    while (*code_end && *code_end != '#' && *code_end != ';') code_end++;
    while (s < code_end && (*s == ' ' || *s == '\t')) s++;
    if (s >= code_end) return false;
    if (*s == '.') {
        /* .inst counts */
        return starts_with(s, ".inst");
    }
    if (is_assignment(line)) return false;
    /* LLVM / GAS: opcode starts with letter or % */
    return isalpha((unsigned char)*s) || *s == '%';
}

/* Extract identifier tokens that look like label refs from an instruction line. */
static void collect_label_refs(const char *line, HashSet *used) {
    const char *s = line;
    /* skip comment */
    size_t len = strlen(line);
    size_t code_len = len;
    for (size_t i = 0; i < len; i++) {
        if (line[i] == '#' || line[i] == ';') {
            code_len = i;
            break;
        }
    }
    s = line;
    const char *end = line + code_len;
    /* skip instruction mnemonic */
    s = skip_ws(s);
    while (s < end && (isalnum((unsigned char)*s) || *s == '%' || *s == '.' || *s == '_'))
        s++;
    while (s < end) {
        if (*s == '"') {
            const char *a = s;
            s++;
            while (s < end && *s != '"') s++;
            if (s < end && *s == '"') s++;
            hashset_add(used, a, (size_t)(s - a));
            continue;
        }
        if (isalpha((unsigned char)*s) || *s == '_' || *s == '.' || *s == '$' || *s == '@') {
            const char *a = s;
            s++;
            while (s < end && (isalnum((unsigned char)*s) || *s == '_' || *s == '.' || *s == '$' || *s == '@'))
                s++;
            /* skip register-ish tiny tokens? keep all; unused filter is conservative */
            hashset_add(used, a, (size_t)(s - a));
            continue;
        }
        s++;
    }
}

/* ---------- document load ---------- */

static Document load_document(FILE *fp) {
    Document doc = {0};
    size_t cap = 0;
    char chunk[1 << 16];
    size_t n;
    while ((n = fread(chunk, 1, sizeof chunk, fp)) > 0) {
        if (doc.buflen + n + 1 > cap) {
            cap = cap ? cap * 2 : 1 << 20;
            while (cap < doc.buflen + n + 1) cap *= 2;
            doc.buf = realloc(doc.buf, cap);
            if (!doc.buf) die("out of memory");
        }
        memcpy(doc.buf + doc.buflen, chunk, n);
        doc.buflen += n;
    }
    if (ferror(fp)) die_errno("read");
    if (!doc.buf) {
        doc.buf = malloc(1);
        if (!doc.buf) die("out of memory");
        doc.buflen = 0;
    }
    doc.buf[doc.buflen] = '\0';

    /* count lines */
    size_t lines_cap = 1024;
    doc.lines = malloc(lines_cap * sizeof *doc.lines);
    if (!doc.lines) die("out of memory");
    char *p = doc.buf;
    doc.lines[doc.nlines++] = p;
    for (; *p; p++) {
        if (*p == '\n') {
            *p = '\0';
            if (p[1] == '\0') break;
            if (doc.nlines >= lines_cap) {
                lines_cap *= 2;
                doc.lines = realloc(doc.lines, lines_cap * sizeof *doc.lines);
                if (!doc.lines) die("out of memory");
            }
            doc.lines[doc.nlines++] = p + 1;
        }
    }
    /* strip CR */
    for (size_t i = 0; i < doc.nlines; i++) {
        size_t L = strlen(doc.lines[i]);
        if (L > 0 && doc.lines[i][L - 1] == '\r')
            doc.lines[i][L - 1] = '\0';
    }
    return doc;
}

/* ---------- .file / .loc parsing ---------- */

static void parse_file_directive(const char *line, FileInfo *files, const Options *opt) {
    /* .file <id> "dir" "name"   OR   .file "path" */
    const char *s = skip_ws(line);
    if (!starts_with(s, ".file")) return;
    s = skip_ws(s + 5);
    if (*s == '"') {
        /* single-arg form — not numbered; ignore for .loc mapping */
        return;
    }
    char *end = NULL;
    long id = strtol(s, &end, 10);
    if (end == s || id < 0 || id >= MAX_FILES) return;
    s = skip_ws(end);
    if (*s != '"') return;
    s++;
    const char *dir = s;
    while (*s && *s != '"') s++;
    if (*s != '"') return;
    size_t dir_len = (size_t)(s - dir);
    s = skip_ws(s + 1);
    if (*s != '"') {
        /* .file id "path" */
        char *path = malloc(dir_len + 1);
        if (!path) die("out of memory");
        memcpy(path, dir, dir_len);
        path[dir_len] = '\0';
        free(files[id].path);
        files[id].path = path;
        files[id].is_user = path_is_user(opt, path);
        return;
    }
    s++;
    const char *name = s;
    while (*s && *s != '"') s++;
    if (*s != '"') return;
    size_t name_len = (size_t)(s - name);
    char *path = malloc(dir_len + 1 + name_len + 1);
    if (!path) die("out of memory");
    memcpy(path, dir, dir_len);
    path[dir_len] = '/';
    memcpy(path + dir_len + 1, name, name_len);
    path[dir_len + 1 + name_len] = '\0';
    free(files[id].path);
    files[id].path = path;
    files[id].is_user = path_is_user(opt, path);
}

static bool parse_loc_file_id(const char *line, int *file_id) {
    const char *s = skip_ws(line);
    if (!starts_with(s, ".loc")) return false;
    s = skip_ws(s + 4);
    char *end = NULL;
    long id = strtol(s, &end, 10);
    if (end == s) return false;
    *file_id = (int)id;
    return true;
}

static bool is_block_end(const char *line) {
    const char *s = skip_ws(line);
    return starts_with(s, ".cfi_endproc") || starts_with(s, ".section") ||
           starts_with(s, ".text") || starts_with(s, ".data") || starts_with(s, ".bss");
}

/* ---------- trim ---------- */

static void squash_spaces(const char *in, char *out) {
    /* leading indent -> at most 2 spaces; collapse runs elsewhere; preserve "strings" */
    const char *s = in;
    char *d = out;
    bool at_start = true;
    while (*s) {
        if (*s == '"') {
            *d++ = *s++;
            while (*s && *s != '"') {
                if (*s == '\\' && s[1]) {
                    *d++ = *s++;
                    *d++ = *s++;
                } else {
                    *d++ = *s++;
                }
            }
            if (*s == '"') *d++ = *s++;
            at_start = false;
            continue;
        }
        if (*s == ' ' || *s == '\t') {
            if (at_start) {
                /* count indent */
                int n = 0;
                while (*s == ' ' || *s == '\t') {
                    n += (*s == '\t') ? 4 : 1;
                    s++;
                }
                if (n > 0) {
                    *d++ = ' ';
                    if (n > 1) *d++ = ' ';
                }
            } else {
                while (*s == ' ' || *s == '\t') s++;
                *d++ = ' ';
            }
            continue;
        }
        at_start = false;
        *d++ = *s++;
    }
    *d = '\0';
}

/* ---------- main filter ---------- */

static void usage(FILE *fp) {
    fprintf(fp,
        "Usage: filter-asm [options] [input.s] [-o output.s]\n"
        "\n"
        "Filters (default: on like CE text-asm defaults):\n"
        "  -d / --directives     strip assembler directives (default on)\n"
        "  -c / --comments       strip comment-only lines (default on)\n"
        "  -l / --labels         strip unused labels (default on)\n"
        "  -t / --trim           squash horizontal whitespace (default off)\n"
        "  -L / --library        strip non-user code via .file/.loc (default off)\n"
        "  --keep-data           with -d, still keep .ascii/.quad/etc after kept labels\n"
        "  --library-sticky      with -L, keep code after user .loc until next proc end\n"
        "                        (closer to CE; default is strict current-.loc only)\n"
        "\n"
        "  --no-directives / --no-comments / --no-labels / --no-library\n"
        "\n"
        "User-source classification for -L (repeatable):\n"
        "  -u / --user SUBSTR    .file path containing SUBSTR is user code\n"
        "                        If none given, only <stdin>/<source>/example.* count\n"
        "\n"
        "  -h / --help           show this help\n");
}

static Options parse_args(int argc, char **argv) {
    Options opt = {
        .directives = true,
        .comments = true,
        .labels = true,
        .library = false,
        .trim = false,
        .keep_data = false,
        .library_sticky = false,
    };
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (strcmp(a, "-h") == 0 || strcmp(a, "--help") == 0) {
            usage(stdout);
            exit(0);
        } else if (strcmp(a, "-d") == 0 || strcmp(a, "--directives") == 0) {
            opt.directives = true;
        } else if (strcmp(a, "--no-directives") == 0) {
            opt.directives = false;
        } else if (strcmp(a, "-c") == 0 || strcmp(a, "--comments") == 0) {
            opt.comments = true;
        } else if (strcmp(a, "--no-comments") == 0) {
            opt.comments = false;
        } else if (strcmp(a, "-l") == 0 || strcmp(a, "--labels") == 0) {
            opt.labels = true;
        } else if (strcmp(a, "--no-labels") == 0) {
            opt.labels = false;
        } else if (strcmp(a, "-t") == 0 || strcmp(a, "--trim") == 0) {
            opt.trim = true;
        } else if (strcmp(a, "-L") == 0 || strcmp(a, "--library") == 0) {
            opt.library = true;
        } else if (strcmp(a, "--no-library") == 0) {
            opt.library = false;
        } else if (strcmp(a, "--keep-data") == 0) {
            opt.keep_data = true;
        } else if (strcmp(a, "--library-sticky") == 0) {
            opt.library_sticky = true;
        } else if (strcmp(a, "-u") == 0 || strcmp(a, "--user") == 0) {
            if (++i >= argc) die("--user needs an argument");
            if (opt.n_user_patterns >= MAX_USER_PATTERNS) die("too many --user patterns");
            opt.user_patterns[opt.n_user_patterns++] = argv[i];
        } else if (strcmp(a, "-o") == 0) {
            if (++i >= argc) die("-o needs an argument");
            opt.output_path = argv[i];
        } else if (a[0] == '-') {
            fprintf(stderr, "filter-asm: unknown option '%s'\n", a);
            usage(stderr);
            exit(2);
        } else if (!opt.input_path) {
            opt.input_path = a;
        } else {
            die("unexpected extra argument");
        }
    }
    return opt;
}

int main(int argc, char **argv) {
    Options opt = parse_args(argc, argv);

    FILE *in = stdin;
    if (opt.input_path) {
        in = fopen(opt.input_path, "rb");
        if (!in) die_errno(opt.input_path);
    }
    Document doc = load_document(in);
    if (in != stdin) fclose(in);

    FileInfo files[MAX_FILES];
    memset(files, 0, sizeof files);

    /* Pass A: parse .file table */
    for (size_t i = 0; i < doc.nlines; i++)
        parse_file_directive(doc.lines[i], files, &opt);

    if (opt.library && opt.n_user_patterns == 0) {
        fprintf(stderr,
            "filter-asm: warning: -L enabled but no --user patterns; "
            "only <stdin>/<source>/example.* count as user code\n");
    }

    /* Pass B: decide library-skip per line (before stripping directives) */
    bool *lib_skip = calloc(doc.nlines, sizeof *lib_skip);
    if (!lib_skip) die("out of memory");

    if (opt.library) {
        int cur_file = -1;
        bool cur_user = false;
        bool sticky_user = false;
        for (size_t i = 0; i < doc.nlines; i++) {
            const char *line = doc.lines[i];
            int fid;
            if (parse_loc_file_id(line, &fid)) {
                cur_file = fid;
                cur_user = (fid >= 0 && fid < MAX_FILES && files[fid].path && files[fid].is_user);
                if (cur_user) sticky_user = true;
                lib_skip[i] = true; /* .loc itself is a directive; mark skip for library pass */
                continue;
            }
            if (is_block_end(line)) {
                sticky_user = false;
                cur_user = false;
                cur_file = -1;
            }

            bool user_here = cur_user || (opt.library_sticky && sticky_user);
            /* No .loc yet / unknown: keep (same idea as CE when source is null) */
            if (cur_file < 0) {
                lib_skip[i] = false;
            } else {
                lib_skip[i] = !user_here;
            }
        }
    }

    /* Pass C: collect label refs from lines we will keep as code */
    HashSet used;
    memset(&used, 0, sizeof used);
    hashset_init(&used, 1024);

    bool *keep = calloc(doc.nlines, sizeof *keep);
    if (!keep) die("out of memory");

    /* First decide keep ignoring unused-label filter; then refine labels. */
    const char *prev_kept_label = NULL;

    for (size_t i = 0; i < doc.nlines; i++) {
        const char *line = doc.lines[i];
        const char *t = skip_ws(line);

        if (*t == '\0') {
            keep[i] = true; /* blank lines; may compact later */
            continue;
        }
        if (opt.library && lib_skip[i]) {
            keep[i] = false;
            continue;
        }
        if (opt.comments && is_comment_only(line)) {
            keep[i] = false;
            continue;
        }

        const char *lname = NULL;
        size_t llen = 0;
        bool is_lab = match_label_def(line, &lname, &llen);

        if (opt.directives && is_directive(line) && !is_lab) {
            if (opt.keep_data && is_data_defn(line) && prev_kept_label) {
                keep[i] = true;
            } else {
                keep[i] = false;
            }
            continue;
        }

        /* Alias assignments are noise for asm view; drop with directives filter. */
        if (opt.directives && is_assignment(line)) {
            keep[i] = false;
            continue;
        }

        if (is_lab) {
            /* tentatively keep; unused filter may drop */
            keep[i] = true;
            prev_kept_label = lname;
            continue;
        }

        keep[i] = true;
        if (has_opcode(line))
            collect_label_refs(line, &used);
    }

    /* Also mark .globl/.global/.weak/.type names as used when directives kept */
    if (!opt.directives) {
        for (size_t i = 0; i < doc.nlines; i++) {
            if (!keep[i]) continue;
            const char *s = skip_ws(doc.lines[i]);
            const char *kw = NULL;
            if (starts_with(s, ".globl")) kw = s + 6;
            else if (starts_with(s, ".global")) kw = s + 7;
            else if (starts_with(s, ".weak")) kw = s + 5;
            if (!kw) continue;
            kw = skip_ws(kw);
            const char *a = kw;
            size_t n = 0;
            if (*a == '"') {
                a++;
                while (a[n] && a[n] != '"') n++;
                hashset_add(&used, kw, n + 2); /* include quotes — label defs may be quoted */
            } else {
                while (a[n] && !isspace((unsigned char)a[n]) && a[n] != ',') n++;
                hashset_add(&used, a, n);
            }
        }
    }

    if (opt.labels) {
        for (size_t i = 0; i < doc.nlines; i++) {
            if (!keep[i]) continue;
            const char *lname = NULL;
            size_t llen = 0;
            if (!match_label_def(doc.lines[i], &lname, &llen)) continue;
            if (!hashset_has(&used, lname, llen))
                keep[i] = false;
        }
    }

    /* Drop label defs with no kept body before the next kept label
     * (common with -L when a call target is used but its body is library). */
    for (size_t i = 0; i < doc.nlines; i++) {
        if (!keep[i]) continue;
        const char *lname = NULL;
        size_t llen = 0;
        if (!match_label_def(doc.lines[i], &lname, &llen)) continue;
        bool has_body = false;
        for (size_t j = i + 1; j < doc.nlines; j++) {
            if (!keep[j]) continue;
            const char *n2 = NULL;
            size_t n2l = 0;
            if (match_label_def(doc.lines[j], &n2, &n2l)) break;
            if (*skip_ws(doc.lines[j]) == '\0') continue;
            has_body = true;
            break;
        }
        if (!has_body) keep[i] = false;
    }

    FILE *out = stdout;
    if (opt.output_path) {
        out = fopen(opt.output_path, "wb");
        if (!out) die_errno(opt.output_path);
    }

    size_t kept = 0, skipped = 0;
    char *trim_buf = NULL;
    size_t trim_cap = 0;

    for (size_t i = 0; i < doc.nlines; i++) {
        if (!keep[i]) {
            skipped++;
            continue;
        }
        /* drop blank lines at start / collapse? keep blanks that separate kept code */
        const char *line = doc.lines[i];
        if (*skip_ws(line) == '\0') {
            /* keep blank only if previous emitted line was non-blank */
            continue; /* omit blanks for denser CE-like output */
        }
        if (opt.trim) {
            size_t need = strlen(line) + 1;
            if (need > trim_cap) {
                trim_cap = need * 2;
                trim_buf = realloc(trim_buf, trim_cap);
                if (!trim_buf) die("out of memory");
            }
            squash_spaces(line, trim_buf);
            fputs(trim_buf, out);
        } else {
            fputs(line, out);
        }
        fputc('\n', out);
        kept++;
    }

    if (out != stdout) fclose(out);

    fprintf(stderr, "filter-asm: %zu lines in, %zu kept, %zu filtered\n", doc.nlines, kept, skipped);

    free(trim_buf);
    free(keep);
    free(lib_skip);
    hashset_free(&used);
    for (int i = 0; i < MAX_FILES; i++) free(files[i].path);
    free(doc.lines);
    free(doc.buf);
    return 0;
}
