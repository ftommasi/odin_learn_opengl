package textures;

import "core:fmt"

import glfw "vendor:glfw"
import gl "vendor:OpenGL"
import stb "vendor:stb/image"


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

        texCoords := [?]f32  {
            0.0, 0.0,  // lower-left corner  
            1.0, 0.0,  // lower-right corner
            0.5, 1.0,   // top-center corner
        };

        vertices := [?] f32 {
            // positions          // colors           // texture coords
            0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
            0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
            -0.5,-0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
            -0.5, 0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0,    // top left 
        };

        indices := [?] i32 {
            0, 1, 3, // first triangle
            1, 2, 3,  // second triangle
        };

        VAO: u32;
        gl.GenVertexArrays(1,&VAO);
        gl.BindVertexArray(VAO);


        VBO : u32;
        gl.GenBuffers(1,&VBO);

        EBO : u32;
        gl.GenBuffers(1,&EBO);

        gl.BindBuffer(gl.ARRAY_BUFFER,VBO)
        gl.BufferData(gl.ARRAY_BUFFER,size_of(vertices),&vertices,gl.STATIC_DRAW)

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,EBO)
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER,size_of(indices),&indices,gl.STATIC_DRAW)

        //Position data
        gl.VertexAttribPointer(0,3,gl.FLOAT,gl.FALSE, size_of(f32)*8, cast(uintptr)0)
        gl.EnableVertexAttribArray(0)

        //Color data
        gl.VertexAttribPointer(1,3,gl.FLOAT,gl.FALSE, size_of(f32)*8, cast(uintptr)(3*size_of(f32)))
        gl.EnableVertexAttribArray(1)

        //Textyre data
        gl.VertexAttribPointer(2,3,gl.FLOAT,gl.FALSE, size_of(f32)*8, cast(uintptr)(6*size_of(f32)))
        gl.EnableVertexAttribArray(2)


        // load and create a texture 
        // -------------------------
        texture1: u32;
        //texture2: u32;

        // texture 1
        // ---------
        gl.GenTextures(1, &texture1);
        gl.BindTexture(gl.TEXTURE_2D, texture1); 
        // set the texture wrapping parameters
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);	// set texture wrapping to gl.REPEAT (default wrapping method)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        // set texture filtering parameters
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        
        width: i32;
        height:i32;
        nrChannels:i32;
        data := stb.load("wall.jpg",&width,&height,&nrChannels,0);
        if data != nil{
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
            gl.GenerateMipmap(gl.TEXTURE_2D);
        }else{
            fmt.println("Failed stb.load() for wall.jpg");
        }
        defer stb.image_free(data);


        // gl.UseProgram(shader_program);
        program_id: u32; ok: bool
        if program_id, ok = gl.load_shaders("./textures.vs", "./textures.fs"); !ok {
            fmt.println("Failed to load shaders.")
            return
        }
        defer gl.DeleteProgram(program_id)
        gl.UseProgram(program_id);
        
        gl.Uniform1i(gl.GetUniformLocation(program_id, "texture1"), 0);
        for (!glfw.WindowShouldClose(window_handle)){
            process_input(window_handle);
            glfw.PollEvents();
            gl.ClearColor(0.2,0.3,0.3,1.0);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            // bind textures on corresponding texture units
            gl.ActiveTexture(gl.TEXTURE0);
            gl.BindTexture(gl.TEXTURE_2D, texture1);

            gl.UseProgram(program_id);
            gl.BindVertexArray(VAO);
            gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil);
            

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


