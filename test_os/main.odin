package test_os

import "core:fmt"
import "core:os"

main :: proc() {
    f, _ := os.open("test_log.txt", flags = {.Write, .Read})
    args := os.args
    for arg in args {
        os.write_string(f, arg)
        os.write_string(f, "\n")
    }
    os.close(f)
}