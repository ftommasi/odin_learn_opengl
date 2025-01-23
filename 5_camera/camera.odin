package camera;

import "core:fmt"
import "core:math"
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

camera_pos := glm.vec3{0,0,3};
camera_target := glm.vec3{0,0,0};
camera_front := glm.vec3{0,0,-1};
camera_direction := glm.normalize(camera_pos - camera_target)

camera_up := glm.vec3{0,1,0};
camera_right := glm.cross(camera_up,camera_direction);



radius :f32 = 10.0;


camera_speed : f32 = 0
last_time :f32 = cast(f32)0
delta_time := last_time
fov : f32 = 45.0

view_direction := glm.vec3{0,0,0} 

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
    glfw.SetCursorPosCallback(window_handle,mouse_callback)
    glfw.SetScrollCallback(window_handle,scroll_callback)
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
        //part 1
        // positions          // colors           // texture coords
        //0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
        //0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
        //-0.5,-0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
        //-0.5, 0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0,    // top left 

        //part 2
        -0.5, -0.5, -0.5,  0.0, 0.0,
        0.5, -0.5, -0.5,  1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5,  0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5, -0.5,  1.0, 1.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
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

    //gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER,EBO)
    //gl.BufferData(gl.ELEMENT_ARRAY_BUFFER,size_of(indices),&indices,gl.STATIC_DRAW)

    //Position data
    gl.VertexAttribPointer(0,3,gl.FLOAT,gl.FALSE, size_of(f32)*5, cast(uintptr)0)
    gl.EnableVertexAttribArray(0)

    //Color data
    gl.VertexAttribPointer(1,2,gl.FLOAT,gl.FALSE, size_of(f32)*5, cast(uintptr)(3*size_of(f32)))
    gl.EnableVertexAttribArray(1)


    gl.Enable(gl.DEPTH_TEST);

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
    if program_id, ok = gl.load_shaders("./camera.vs", "./camera.fs"); !ok {
        fmt.println("Failed to load shaders.")
        return
    }
    defer gl.DeleteProgram(program_id)
    gl.UseProgram(program_id);

    gl.Uniform1i(gl.GetUniformLocation(program_id, "texture1"), 0);
    gl.Uniform1i(gl.GetUniformLocation(program_id, "texture2"), 1);


    cubePositions := [?] glm.vec3{
        glm.vec3{ 0.0,  0.0,  0.0}, 
        glm.vec3{ 2.0,  5.0, -15.0}, 
        glm.vec3{-1.5, -2.2, -2.5},  
        glm.vec3{-3.8, -2.0, -12.3},  
        glm.vec3{ 2.4, -0.4, -3.5},  
        glm.vec3{-1.7,  3.0, -7.5},  
        glm.vec3{ 1.3, -2.0, -2.5},  
        glm.vec3{ 1.5,  2.0, -2.5}, 
        glm.vec3{ 1.5,  0.2, -1.5}, 
        glm.vec3{-1.3,  1.0, -1.5}  ,
    };


    direction : glm.vec3;
    direction.x = math.cos_f32(glm.radians_f32(yaw)) * math.cos_f32(glm.radians_f32(pitch))
    direction.x = math.sin_f32(glm.radians_f32(pitch))
    direction.z = math.sin_f32(glm.radians_f32(yaw))* math.cos_f32(glm.radians_f32(pitch))

    for (!glfw.WindowShouldClose(window_handle)){
        process_input(window_handle);
        current_time :=  cast(f32)glfw.GetTime()
        delta_time = current_time - last_time
        last_time = current_time
        camera_speed = 5.5 * delta_time

        if glfw.GetKey(window_handle, glfw.KEY_W) == glfw.PRESS {
            camera_pos += camera_speed * camera_front;
        }
        if glfw.GetKey(window_handle, glfw.KEY_S) == glfw.PRESS{
            camera_pos -= camera_speed * camera_front;
        }
        if glfw.GetKey(window_handle, glfw.KEY_A) == glfw.PRESS{
            camera_pos -= glm.normalize(glm.cross_vec3(camera_front,camera_up)) * camera_speed;
        }
        if glfw.GetKey(window_handle, glfw.KEY_D) == glfw.PRESS {
            camera_pos += glm.normalize(glm.cross_vec3(camera_front,camera_up)) * camera_speed;
        }
        glfw.PollEvents();
        gl.ClearColor(0.2,0.3,0.3,1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

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

        //This is part2
        cube_rotate_vec : glm.vec3 = {0.5,1,0};
        model *= glm.mat4Rotate(cube_rotate_vec, cast(f32)glfw.GetTime() * glm.radians_f32(50));

        gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, &model[0][0]);




        //view:= glm.mat4(1.0);
        //Note that we translate in the opposite direction that we want to move in
        view_vec : glm.vec3 = {0,0,-3};
        camX := math.sin_f32(cast(f32)glfw.GetTime()) * radius;
        camZ := math.cos_f32(cast(f32)glfw.GetTime()) * radius;
        //view := glm.mat4LookAt(glm.vec3{camX,0,camZ},glm.vec3{0,0,0},glm.vec3{0,1,0});
        view := glm.mat4LookAt(camera_pos,camera_pos + camera_front ,camera_up);
        view *= glm.mat4Translate(view_vec); 



        viewLoc := gl.GetUniformLocation(program_id,"view");
        gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, &view[0][0]);
        projection:= glm.mat4(1.0);

        projectionLoc := gl.GetUniformLocation(program_id,"projection");
        projection *= glm.mat4Perspective(glm.radians_f32(fov), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
        gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, &projection[0][0]);


        gl.BindVertexArray(VAO);
        //part 1
        //gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil);

        //part2
        gl.DrawArrays(gl.TRIANGLES, 0, 36);

        for pos in cubePositions {
            cur_model := glm.mat4(1.0);
            cur_model *= glm.mat4Translate(pos);

            cube_rotate_vec : glm.vec3 = {0.5,1,0};
            cur_model *= glm.mat4Rotate(cube_rotate_vec*pos, cast(f32)glfw.GetTime() * glm.radians_f32(50));

            cur_modelLoc := gl.GetUniformLocation(program_id,"model");
            gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, &cur_model[0][0]);
            gl.DrawArrays(gl.TRIANGLES, 0, 36);

        }


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
    if(glfw.GetKey(window, glfw.KEY_G) == glfw.PRESS){
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
    }

    if(glfw.GetKey(window, glfw.KEY_F) == glfw.PRESS){
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
    }
}

firstMouse := false; //global static
yaw : f32 = 90.0
pitch : f32 = 45.0
lastX :f32= 0;
lastY :f32= 0;


mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos: f64, ypos: f64)
{

    if firstMouse
    {
        lastX = cast(f32)xpos;
        lastY = cast(f32)ypos;
        firstMouse = false;
    }

    xoffset := cast(f32)xpos - lastX;
    yoffset := lastY - cast(f32)ypos; 
    lastX = cast(f32)xpos;
    lastY = cast(f32)ypos;

    sensitivity : f32 = 0.1;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw   += xoffset;
    pitch += yoffset;

    if pitch > 89.0 {
        pitch = 89.0;
    }
    if pitch < -89.0 {
        pitch = -89.0;
    }

    direction : glm.vec3;
    direction.x = math.cos(glm.radians_f32(yaw)) * math.cos(glm.radians_f32(pitch));
    direction.y = math.sin(glm.radians_f32(pitch));
    direction.z = math.sin(glm.radians_f32(yaw)) * math.cos(glm.radians_f32(pitch));
    camera_front= glm.normalize_vec3(direction);
}  

scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset: f64, yoffset: f64)
{
 fov -= cast(f32)yoffset
    if fov < 1.0 {
        fov = 10.0
    }
    if fov > 45.0 {
        fov = 45.0
    }
}  

