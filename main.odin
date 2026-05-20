package main


import "core:os"
import "core:fmt"
import "core:time"


when ODIN_OS == .Linux {
    FFMPEG_COMMAND : string : "ffmpeg -f v4l2 -framerate 30 -video_size 640x480 -i /dev/video0 -c:v libx264 -preset ultrafast -tune zerolatency -f mpegts - | ./ezchat"
} else when ODIN_OS == .Windows {
    FFMPEG_COMMAND : string : "ffmpeg -f dshow -framerate 30 -video_size 640x480 -i video=\"Integrated Camera\" -c:v libx264 -preset ultrafast -tune zerolatency -f mpegts - | ezchat.exe"
} else when ODIN_OS == .Darwin {
    FFMPEG_COMMAND : string : "ffmpeg -f avfoundation -framerate 30 -video_size 640x480 -i \"0:0\" -c:v libx264 -preset ultrafast -tune zerolatency -f mpegts - | ./ezchat"
}

Read_Pipe :: distinct ^os.File
Write_Pipe :: distinct ^os.File

safe_pipe :: proc() -> (Read_Pipe, Write_Pipe, os.Error) {
    read_pipe, write_pipe, pipe_status := os.pipe()

    return Read_Pipe(read_pipe), Write_Pipe(write_pipe), pipe_status
}

main :: proc() {

    read_pipe, write_pipe, pipe_status := os.pipe()
    
    if pipe_status != nil {
        fmt.println("---------------------------")
        fmt.println("Failed to open pipe because: ", pipe_status)
        fmt.println("---------------------------")
    }

    ffmpeg_process_description := os.Process_Desc{
        working_dir = "",
        command = {
            "ffmpeg",
            "-f", "dshow",
            "-framerate", "30",
            "-video_size", "1280x720",
            "-i", "video=Integrated Camera",
            "-c:v", "libx264",
            "-preset", "ultrafast",
            "-tune", "zerolatency",
            "-f", "mpegts",
            // "-loglevel quiet",
            "pipe:1",
        },
        stdout = write_pipe,
    }

    ffmpeg_process, process_start_error := os.process_start(ffmpeg_process_description)
    
    defer {
        fmt.println("DEFER CALLED!")
        blech := os.process_kill(ffmpeg_process)
        fmt.println("Blech_error: ", blech)
    }
    if process_start_error != nil {
        fmt.println("---------------------------")
        fmt.println("Failed to start ffmpeg process because: ", pipe_status)
        fmt.println("---------------------------")
    }

    fmt.println("ffmpeg_process: ", ffmpeg_process)

    ffmpeg_data_buffer := make([]u8, 1500)
    test_file, test_file_error := os.create("test_video.ts")
    if test_file_error != nil {
        fmt.println("-------------------")
        fmt.println("Failed to create test_video file because: ", test_file_error)
        fmt.println("-------------------")
    }

    t : time.Stopwatch
    time.stopwatch_start(&t)
    fmt.println(t)
    for time.stopwatch_duration(t) < 5 * time.Second{
        has_data, data_error := os.pipe_has_data(read_pipe)
        if has_data {
            // fmt.println("Has data!")
            bytes_read, read_status := os.read(read_pipe, ffmpeg_data_buffer)
            x := bytes_read
            os.write(test_file, ffmpeg_data_buffer[:bytes_read])
            fmt.println("Bytes read: ", bytes_read)

        } else if data_error == nil {
            // fmt.println("No data available")
        } else {
            fmt.println("Error attempting to check for data: ", data_error)
        }
    }

    return
}


//  ffmpeg -f dshow -framerate 30 -video_size 1280x720 -i video="Integrated Camera" -c:v libx264 -preset ultrafast -tune zerolatency -f mpegts -loglevel quiet pipe:1