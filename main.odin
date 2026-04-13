package ezchat


import "core:fmt"
import "core:c"

import "vendor:sdl3"
import "vendor:stb/image"

main :: proc() {
    
    fmt.println("EZCHAT!!!")
    
    flags : sdl3.InitFlags = sdl3.InitFlags {.VIDEO, .AUDIO, .EVENTS, .CAMERA, .SENSOR, .JOYSTICK, .HAPTIC, .GAMEPAD} 

    success := sdl3.Init(flags)
    if !success {
        fmt.println(sdl3.GetError())
    }

    count : c.int
    cameras := sdl3.GetCameras(&count)
    specs := sdl3.GetCameraSupportedFormats(cameras[0], &count)
    // for i in 0..<count {
    //     fmt.println(specs[i])
    // }
    spec := sdl3.CameraSpec{format = .MJPG, colorspace = .SRGB, width = 1280, height = 720, framerate_numerator = 30, framerate_denominator = 1}
    camera := sdl3.OpenCamera(cameras[0], &spec)
    if camera == nil {
        fmt.println("Camera did not open")
        return
    }

    camera_permission := sdl3.GetCameraPermissionState(camera)
    if camera_permission != .APPROVED {
        fmt.println("Denied access to camera")
        return
    }

    actual_spec : sdl3.CameraSpec 
    sdl3.GetCameraFormat(camera, &actual_spec)
    fmt.println("Actual_spec: ", actual_spec)

    window_flags := sdl3.WindowFlags {}
    window := sdl3.CreateWindow("EzChat", spec.width, spec.height, window_flags)
    
    fmt.println(spec)
    timestamp : u64
    renderer := sdl3.CreateRenderer(window, nil)
    video_texture := sdl3.CreateTexture(renderer, .ABGR8888, .STREAMING, spec.width, spec.height)
    if video_texture == nil {
        fmt.println("Video texture is nil")
        return
    }
    for {
        event : sdl3.Event
        event_polled := sdl3.PollEvent(&event)
        
        if event.type == .QUIT {
            return
        }
        
        frame := sdl3.AcquireCameraFrame(camera, &timestamp)
        
        sdl3.Delay(10)
        if frame == nil {
            fmt.println("Frame is nil")
            sdl3.ReleaseCameraFrame(camera, frame)
            continue
        }
        
        width, height, channels : c.int
        decoded := image.load_from_memory(cast([^]u8)(frame.pixels), frame.pitch*frame.h, &width, &height, &channels, 4)
        if decoded == nil {
            fmt.println("Decoding failed")
            return
        }
        
        sdl3.UpdateTexture(video_texture, nil, decoded, width*4)

        sdl3.RenderTexture(renderer, video_texture, nil, nil)
        sdl3.RenderPresent(renderer)
        sdl3.ReleaseCameraFrame(camera, frame)
    }

    return
    
}