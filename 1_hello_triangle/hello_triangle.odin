package hello_triangle;

import "core:fmt"
import glfw "vendor:glfw"
import gl "vendor:OpenGL"


//Const set up
	WINDOW_WIDTH  :: 854
	WINDOW_HEIGHT :: 480

    GL_VERSION_MAJOR :: 4
    GL_VERSION_MINOR :: 6

main :: proc() {
//initialise glfw
    glfw.Init()
    defer glfw.Terminate()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE,glfw.OPENGL_CORE_PROFILE)
    window_handle :glfw.WindowHandle= glfw.CreateWindow(WINDOW_WIDTH,WINDOW_HEIGHT,"Hello Window", nil,nil)
    if (window_handle == nil){
    fmt.eprint("Failed to create glfw window! \n")
        }
    glfw.MakeContextCurrent(window_handle);
    glfw.SwapInterval(0);
    glfw.SetFramebufferSizeCallback(window_handle,frame_buffer_size_callback)
  //OpenGL set up
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, proc(p: rawptr, name: cstring) {
		(^rawptr)(p)^ = glfw.GetProcAddress(name);
	});

    gl.Viewport(0,0,WINDOW_WIDTH,WINDOW_HEIGHT);
    //Shader set up
    
    //Plain ass triangle
    //vertices :=[?]f32{
    //    0.0, 0.5,  0.0,
    //    -0.5,-0.5, 0.0,
    //    0.5, -0.5, 0.0,
    //   };

    //COOL ass triangle (with color data)
    vertices :=[?]f32{
        //Positions   || //Colors
        0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
        -0.5,-0.5, 0.0, 0.0, 1.0, 0.0,
        0.0, 0.5,  0.0, 0.0, 0.0, 1.0,
       };

    VAO: u32;
    gl.GenVertexArrays(1,&VAO);
    gl.BindVertexArray(VAO);


    VBO : u32;
    gl.GenBuffers(1,&VBO);
    
    gl.BindBuffer(gl.ARRAY_BUFFER,VBO)
    gl.BufferData(gl.ARRAY_BUFFER,size_of(vertices),&vertices,gl.STATIC_DRAW)

    //Position data
    gl.VertexAttribPointer(0,3,gl.FLOAT,gl.FALSE, size_of(f32)*6, cast(uintptr)0)
    gl.EnableVertexAttribArray(0)
    
    //Color data
    gl.VertexAttribPointer(1,3,gl.FLOAT,gl.FALSE, size_of(f32)*6, cast(uintptr)(3*size_of(f32)))
    gl.EnableVertexAttribArray(1)

    

   // gl.UseProgram(shader_program);
    program_id: u32; ok: bool
    if program_id, ok = gl.load_shaders("./hello_triangle.vs", "./hello_triangle.fs"); !ok {
        fmt.println("Failed to load shaders.")
        return
    }
    defer gl.DeleteProgram(program_id)
    gl.UseProgram(program_id);

    for (!glfw.WindowShouldClose(window_handle)){
        process_input(window_handle);
        glfw.PollEvents();
        gl.ClearColor(0.2,0.3,0.3,1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        //gl.UseProgram(shader_program);
        gl.UseProgram(program_id);
        gl.BindVertexArray(VAO);
        gl.DrawArrays(gl.TRIANGLES,0,3);

        glfw.SwapBuffers(window_handle);
    }

}

frame_buffer_size_callback :: proc "c" (window: glfw.WindowHandle, width,height :i32){
    gl.Viewport(0,0,width,height);
}


process_input:: proc(window: glfw.WindowHandle){
    if(glfw.GetKey(window,glfw.KEY_ESCAPE) == glfw.PRESS){
        glfw.SetWindowShouldClose(window, true)
    }
    if(glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS){
     gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
    }

    if(glfw.GetKey(window, glfw.KEY_F) == glfw.PRESS){
     gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
    }
}


