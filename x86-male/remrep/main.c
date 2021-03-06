#include <stdio.h>

extern char *remrep(char *s);

char visited[32];

char *remrep1(char *s) {
    char *source = s;
    char *dest = s;

    while (1) {
        char currentChar = *source;

        if (currentChar == 0) {
            break;
        }

        // check if char in visited, if yes - skip it
        char *visitedPointer = visited;
        int isVisited = 0;
        while (1) {
            char visitedChar = *visitedPointer;

            if (visitedChar == 0) {
                break;
            }

            if (visitedChar == currentChar) {
                isVisited = 1;
                break;
            }

            visitedPointer++;
        }

        // if not isVisited, write to dest and add to visited
        if (isVisited == 0) {
            *dest = currentChar;
            dest++;

            // add to visited
            *visitedPointer = currentChar;
        }

        source++;
    }

    *dest = 0;
    return s;
}


int main() {

    char src[] = "thequickbrownfoxjumpsoverthelazydog";

    char *out = remrep(src);

    printf("%s", out);

    return 0;
}
