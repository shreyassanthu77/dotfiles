/*
 * Minimal Compiler-Explorer-style assembly filter.
 *
 * Configurable; not tied to a particular language. Works best on LLVM/GAS
 * text asm (clang, rustc, zig -femit-asm, etc.).
 *
 * Build:  make / make install   (installs to ~/.local/bin)
 * Usage:  filter-asm [options] [input.s] [-o output.s]
 */

#define _DEFAULT_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_FILES 4096
#define MAX_USER_PATTERNS 64

typedef struct {
    bool directives;
    bool comments;
    bool labels;
    bool library;
    bool trim;
    bool keep_data;
    bool markers;
    /* After seeing user .loc, keep following lines until .cfi_endproc/.section
     * (closer to CE). Default off = strict: only while current .loc is user. */
    bool library_sticky;
    char *user_patterns[MAX_USER_PATTERNS]; /* owned, resolved */
    int n_user_patterns;
    char *cwd; /* owned absolute cwd */
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

typedef struct {
    int file_id; /* -1 if unknown */
    int line;
} LocInfo;

/* ---------- small helpers ---------- */

static void die(const char *msg) {
    fprintf(stderr, "filter-asm: %s\n", msg);
    exit(1);
}

static void die_errno(const char *msg) {
    fprintf(stderr, "filter-asm: %s: %s\n", msg, strerror(errno));
    exit(1);
}

static char *xstrdup(const char *s) {
    size_t n = strlen(s) + 1;
    char *p = malloc(n);
    if (!p) die("out of memory");
    memcpy(p, s, n);
    return p;
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

static bool is_builtin_main_source(const char *path) {
    if (strcmp(path, "<stdin>") == 0 || strcmp(path, "<source>") == 0 || strcmp(path, "-") == 0)
        return true;
    const char *base = strrchr(path, '/');
    base = base ? base + 1 : path;
    return starts_with(base, "example.");
}

/* Resolve -u pattern: "." and "./..." are relative to cwd. */
static char *resolve_user_pattern(const char *cwd, const char *pat) {
    if (strcmp(pat, ".") == 0) {
        return xstrdup(cwd);
    }
    if (starts_with(pat, "./")) {
        size_t n = strlen(cwd) + 1 + strlen(pat + 2) + 1;
        char *joined = malloc(n);
        if (!joined) die("out of memory");
        snprintf(joined, n, "%s/%s", cwd, pat + 2);
        char *rp = realpath(joined, NULL);
        if (rp) {
            free(joined);
            return rp;
        }
        return joined;
    }
    /* Absolute or plain substring (e.g. "/src/", "main.zig") */
    if (pat[0] == '/') {
        char *rp = realpath(pat, NULL);
        if (rp) return rp;
    }
    return xstrdup(pat);
}

static void add_user_pattern(Options *opt, const char *pat) {
    if (opt->n_user_patterns >= MAX_USER_PATTERNS) die("too many --user patterns");
    char *resolved = resolve_user_pattern(opt->cwd, pat);
    for (int i = 0; i < opt->n_user_patterns; i++) {
        if (strcmp(opt->user_patterns[i], resolved) == 0) {
            free(resolved);
            return;
        }
    }
    opt->user_patterns[opt->n_user_patterns++] = resolved;
}

static bool path_is_user(const Options *opt, const char *path) {
    if (is_builtin_main_source(path)) return true;
    for (int i = 0; i < opt->n_user_patterns; i++) {
        if (str_contains(path, opt->user_patterns[i]))
            return true;
    }
    return false;
}

/* Prefer path relative to cwd for display. */
static const char *display_path(const Options *opt, const char *path, char *buf, size_t buflen) {
    size_t cwd_len = strlen(opt->cwd);
    if (starts_with(path, opt->cwd) && (path[cwd_len] == '/' || path[cwd_len] == '\0')) {
        const char *rel = path + cwd_len;
        while (*rel == '/') rel++;
        if (*rel) {
            snprintf(buf, buflen, "%s", rel);
            return buf;
        }
    }
    return path;
}

/* ---------- string set ---------- */

static uint32_t fnv1a(const char *s, size_t n) {
    uint32_t h = 2166136261u;
    for (size_t i = 0; i < n; i++) {
        h ^= (unsigned char)s[i];
        h *= 16777619u;
    }
    return h;
}

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
    const char *rest = skip_ws(s + 1);
    if (*rest != '\0') return false;
    *name = start;
    *namelen = (size_t)(s - start);
    return true;
}

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
    const char *code_end = s;
    while (*code_end && *code_end != '#' && *code_end != ';') code_end++;
    while (s < code_end && (*s == ' ' || *s == '\t')) s++;
    if (s >= code_end) return false;
    if (*s == '.') return starts_with(s, ".inst");
    if (is_assignment(line)) return false;
    return isalpha((unsigned char)*s) || *s == '%';
}

static void collect_label_refs(const char *line, HashSet *used) {
    size_t len = strlen(line);
    size_t code_len = len;
    for (size_t i = 0; i < len; i++) {
        if (line[i] == '#' || line[i] == ';') {
            code_len = i;
            break;
        }
    }
    const char *s = line;
    const char *end = line + code_len;
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
    for (size_t i = 0; i < doc.nlines; i++) {
        size_t L = strlen(doc.lines[i]);
        if (L > 0 && doc.lines[i][L - 1] == '\r')
            doc.lines[i][L - 1] = '\0';
    }
    return doc;
}

/* ---------- .file / .loc parsing ---------- */

static void parse_file_directive(const char *line, FileInfo *files, const Options *opt) {
    const char *s = skip_ws(line);
    if (!starts_with(s, ".file")) return;
    s = skip_ws(s + 5);
    if (*s == '"') return;
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

/* .loc <file> <line> <column> ... */
static bool parse_loc(const char *line, int *file_id, int *src_line) {
    const char *s = skip_ws(line);
    if (!starts_with(s, ".loc")) return false;
    if (s[4] != ' ' && s[4] != '\t') return false;
    s = skip_ws(s + 4);
    char *end = NULL;
    long id = strtol(s, &end, 10);
    if (end == s) return false;
    s = skip_ws(end);
    long ln = strtol(s, &end, 10);
    if (end == s) return false;
    *file_id = (int)id;
    *src_line = (int)ln;
    return true;
}

static bool is_block_end(const char *line) {
    const char *s = skip_ws(line);
    return starts_with(s, ".cfi_endproc") || starts_with(s, ".section") ||
           starts_with(s, ".text") || starts_with(s, ".data") || starts_with(s, ".bss");
}

/* ---------- trim ---------- */

static void squash_spaces(const char *in, char *out) {
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

/* ---------- CLI ---------- */

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
        "  -m / --markers        emit # file:line block markers (default on)\n"
        "  --keep-data           with -d, still keep .ascii/.quad/etc after kept labels\n"
        "  --library-sticky      with -L, keep code after user .loc until next proc end\n"
        "\n"
        "  --no-directives / --no-comments / --no-labels / --no-library / --no-markers\n"
        "\n"
        "User-source classification for -L (repeatable):\n"
        "  -u / --user SUBSTR    .file path containing SUBSTR is user code\n"
        "                        '.' and './path' are resolved against $PWD\n"
        "                        PWD is always included by default\n"
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
        .markers = true,
        .library_sticky = false,
    };

    char cwd_buf[PATH_MAX];
    if (!getcwd(cwd_buf, sizeof cwd_buf)) die_errno("getcwd");
    char *rp = realpath(cwd_buf, NULL);
    opt.cwd = rp ? rp : xstrdup(cwd_buf);

    /* Collect raw -u values first, then resolve after cwd is known. */
    const char *raw_users[MAX_USER_PATTERNS];
    int n_raw = 0;

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
        } else if (strcmp(a, "-m") == 0 || strcmp(a, "--markers") == 0) {
            opt.markers = true;
        } else if (strcmp(a, "--no-markers") == 0) {
            opt.markers = false;
        } else if (strcmp(a, "--keep-data") == 0) {
            opt.keep_data = true;
        } else if (strcmp(a, "--library-sticky") == 0) {
            opt.library_sticky = true;
        } else if (strcmp(a, "-u") == 0 || strcmp(a, "--user") == 0) {
            if (++i >= argc) die("--user needs an argument");
            if (n_raw >= MAX_USER_PATTERNS) die("too many --user patterns");
            raw_users[n_raw++] = argv[i];
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

    /* PWD is always a default -u pattern. */
    add_user_pattern(&opt, ".");
    for (int i = 0; i < n_raw; i++)
        add_user_pattern(&opt, raw_users[i]);

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

    for (size_t i = 0; i < doc.nlines; i++)
        parse_file_directive(doc.lines[i], files, &opt);

    LocInfo *locs = calloc(doc.nlines, sizeof *locs);
    bool *lib_skip = calloc(doc.nlines, sizeof *lib_skip);
    if (!locs || !lib_skip) die("out of memory");

    /* Track .loc for every line; optionally mark library skips. */
    {
        int cur_file = -1;
        int cur_line = 0;
        bool cur_user = false;
        bool sticky_user = false;
        for (size_t i = 0; i < doc.nlines; i++) {
            const char *line = doc.lines[i];
            int fid, ln;
            if (parse_loc(line, &fid, &ln)) {
                cur_file = fid;
                cur_line = ln;
                cur_user = (fid >= 0 && fid < MAX_FILES && files[fid].path && files[fid].is_user);
                if (cur_user) sticky_user = true;
                locs[i].file_id = cur_file;
                locs[i].line = cur_line;
                lib_skip[i] = true; /* .loc is a directive */
                continue;
            }
            if (is_block_end(line)) {
                sticky_user = false;
                cur_user = false;
                cur_file = -1;
                cur_line = 0;
            }
            locs[i].file_id = cur_file;
            locs[i].line = cur_line;

            if (opt.library) {
                bool user_here = cur_user || (opt.library_sticky && sticky_user);
                lib_skip[i] = (cur_file >= 0) && !user_here;
            }
        }
    }

    HashSet used;
    memset(&used, 0, sizeof used);
    hashset_init(&used, 1024);

    bool *keep = calloc(doc.nlines, sizeof *keep);
    if (!keep) die("out of memory");

    const char *prev_kept_label = NULL;

    for (size_t i = 0; i < doc.nlines; i++) {
        const char *line = doc.lines[i];
        const char *t = skip_ws(line);

        if (*t == '\0') {
            keep[i] = true;
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
            keep[i] = opt.keep_data && is_data_defn(line) && prev_kept_label;
            continue;
        }

        if (opt.directives && is_assignment(line)) {
            keep[i] = false;
            continue;
        }

        if (is_lab) {
            keep[i] = true;
            prev_kept_label = lname;
            continue;
        }

        keep[i] = true;
        if (has_opcode(line))
            collect_label_refs(line, &used);
    }

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
                hashset_add(&used, kw, n + 2);
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
    char path_buf[PATH_MAX];
    int last_marker_file = -2;
    int last_marker_line = -2;

    for (size_t i = 0; i < doc.nlines; i++) {
        if (!keep[i]) {
            skipped++;
            continue;
        }
        const char *line = doc.lines[i];
        if (*skip_ws(line) == '\0')
            continue;

        if (opt.markers) {
            int fid = locs[i].file_id;
            int ln = locs[i].line;
            if (fid >= 0 && fid < MAX_FILES && files[fid].path &&
                (fid != last_marker_file || ln != last_marker_line)) {
                const char *shown = display_path(&opt, files[fid].path, path_buf, sizeof path_buf);
                if (ln > 0)
                    fprintf(out, "# %s:%d\n", shown, ln);
                else
                    fprintf(out, "# %s\n", shown);
                last_marker_file = fid;
                last_marker_line = ln;
                kept++;
            }
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
    free(locs);
    hashset_free(&used);
    for (int i = 0; i < MAX_FILES; i++) free(files[i].path);
    for (int i = 0; i < opt.n_user_patterns; i++) free(opt.user_patterns[i]);
    free(opt.cwd);
    free(doc.lines);
    free(doc.buf);
    return 0;
}
