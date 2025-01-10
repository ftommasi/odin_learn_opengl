package coordinates;

import "core:fmt"
import glm "core:math/linalg/glsl"
//import hlm "core:math/linalg/hlsl" ??

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

        data := stb.load("container.jpg",&width,&height,&nrChannels,0);
        if data != nil{
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
            gl.GenerateMipmap(gl.TEXTURE_2D);
        }else{
            fmt.println("Failed stb.load() for container.jpg");
        }
        defer stb.image_free(data);

        // load and create a texture 
        // -------------------------
        texture2: u32;
        width2: i32;
        height2:i32;
        nrChannels2:i32;
        //texture2: u32;

        // texture 2
        // ---------
        gl.GenTextures(1, &texture2);
        gl.BindTexture(gl.TEXTURE_2D, texture2); 
        // set the texture wrapping parameters
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);	// set texture wrapping to gl.REPEAT (default wrapping method)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        // set texture filtering parameters
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

        data2 := stb.load("awesomeface.png",&width2,&height2,&nrChannels2,0);
        if data2 != nil{
            gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data2);
            gl.GenerateMipmap(gl.TEXTURE_2D);
        }else{
            fmt.println("Failed stb.load() for awesomeface.png");
        }
        defer stb.image_free(data2);

        // gl.UseProgram(shader_program);
        program_id: u32; ok: bool
        if program_id, ok = gl.load_shaders("./coordinates.vs", "./coordinates.fs"); !ok {
            fmt.println("Failed to load shaders.")
            return
        }
        defer gl.DeleteProgram(program_id)
        gl.UseProgram(program_id);
        
        gl.Uniform1i(gl.GetUniformLocation(program_id, "texture1"), 0);
        gl.Uniform1i(gl.GetUniformLocation(program_id, "texture2"), 1);
        for (!glfw.WindowShouldClose(window_handle)){
            process_input(window_handle);
            glfw.PollEvents();
            gl.ClearColor(0.2,0.3,0.3,1.0);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            // bind textures on corresponding texture units
            gl.ActiveTexture(gl.TEXTURE0);
            gl.BindTexture(gl.TEXTURE_2D, texture1);

            gl.ActiveTexture(gl.TEXTURE1);
            gl.BindTexture(gl.TEXTURE_2D, texture2);

            gl.UseProgram(program_id);

            model:= glm.mat4(1.0);
            model_vec : glm.vec3 = {1,0,0};
            model *= glm.mat4Rotate(model_vec,glm.radians_f32(-55)); 
            modelLoc := gl.GetUniformLocation(program_id,"model");
            gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, &model[0][0]);

            view:= glm.mat4(1.0);
            //Note that we translate in the opposite direction that we want to move in
            view_vec : glm.vec3 = {0,0,-3};
            view *= glm.mat4Translate(view_vec); 
            
            viewLoc := gl.GetUniformLocation(program_id,"view");
            gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, &view[0][0]);
            projection:= glm.mat4(1.0);
            
            projectionLoc := gl.GetUniformLocation(program_id,"projection");
            projection *= glm.mat4Perspective(glm.radians_f32(45.0), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
            gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, &projection[0][0]);
            

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


