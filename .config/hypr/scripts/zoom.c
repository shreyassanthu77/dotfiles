#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void printHelp(char *name) {
  printf("Usage: %s <command>\n", name);
  printf("	-h  Display this help message\n");
  printf("	-i zoom in\n");
  printf("	-o zoom out\n");
  printf("	-t zoom toggle\n");
}

const char *STATE_FILE = "/tmp/zoom_state";
const float ZOOM_STEP = 0.2;
const char ZOOM_CMD[] = "hyprctl keyword cursor:zoom_factor %.2f";
const size_t ZOOM_CMD_SIZE = sizeof(ZOOM_CMD);

typedef struct {
  float state;
  int toggle; // 0: off, 1: on
} ZoomState;

void setState(float state, int toggle) {
  FILE *file = fopen(STATE_FILE, "w");
  if (file == NULL) {
    fprintf(stderr, "Failed to open file %s\n", STATE_FILE);
    exit(1);
  }

  fprintf(file, "%.2f\n", state);
  fprintf(file, "%d\n", toggle);
  fclose(file);

  if (toggle == 1) {
    state = 1.0;
  }

  char cmd[ZOOM_CMD_SIZE];
  snprintf(cmd, ZOOM_CMD_SIZE, ZOOM_CMD, state);
  system(cmd);
}

ZoomState readState() {
  FILE *file = fopen(STATE_FILE, "r");
  if (file == NULL) {
    setState(1.0, 1);
    return (ZoomState){1.0, 1};
  }

  ZoomState state;
  fscanf(file, "%f", &state.state);
  fscanf(file, "%d", &state.toggle);
  fclose(file);
  return state;
}

#define max(a, b) ((a) > (b) ? (a) : (b))

int main(int argc, char *argv[]) {
  if (argc < 2 || strcmp(argv[1], "-h") == 0) {
    printHelp(argv[0]);
    return 1;
  }

  ZoomState s = readState();
  float state = s.state;
  if (strcmp(argv[1], "-i") == 0) {
    setState(state + ZOOM_STEP, 0);
  } else if (strcmp(argv[1], "-o") == 0) {
    setState(max(1.0, state - ZOOM_STEP), 0);
  } else if (strcmp(argv[1], "-t") == 0) {
    if (s.toggle == 0) {
      setState(s.state, 1);
    } else {
      setState(s.state, 0);
    }
  } else {
    printf("Unknown command: %s\n", argv[1]);
    return 1;
  }

  return 0;
}
