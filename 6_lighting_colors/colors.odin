package colors;

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

    vertices := [?] f32 {
        //prev examples
        // positions          // colors           // texture coords
        //0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0,   // top right
        //0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0,   // bottom right
        //-0.5,-0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0,   // bottom left
        //-0.5, 0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0,    // top left 

        //cube verts
        -0.5, -0.5, -0.5,
        0.5, -0.5, -0.5, 
        0.5,  0.5, -0.5, 
        0.5,  0.5, -0.5, 
        -0.5,  0.5, -0.5,
        -0.5, -0.5, -0.5,

        -0.5, -0.5,  0.5,
        0.5, -0.5,  0.5, 
        0.5,  0.5,  0.5, 
        0.5,  0.5,  0.5, 
        -0.5,  0.5,  0.5,
        -0.5, -0.5,  0.5,

        -0.5,  0.5,  0.5,
        -0.5,  0.5, -0.5,
        -0.5, -0.5, -0.5,
        -0.5, -0.5, -0.5,
        -0.5, -0.5,  0.5,
        -0.5,  0.5,  0.5,

        0.5,  0.5,  0.5, 
        0.5,  0.5, -0.5, 
        0.5, -0.5, -0.5, 
        0.5, -0.5, -0.5, 
        0.5, -0.5,  0.5, 
        0.5,  0.5,  0.5, 

        -0.5, -0.5, -0.5,
        0.5, -0.5, -0.5, 
        0.5, -0.5,  0.5, 
        0.5, -0.5,  0.5, 
        -0.5, -0.5,  0.5,
        -0.5, -0.5, -0.5,

        -0.5,  0.5, -0.5,
        0.5,  0.5, -0.5, 
        0.5,  0.5,  0.5, 
        0.5,  0.5,  0.5, 
        -0.5,  0.5,  0.5,
        -0.5,  0.5, -0.5,
    };



    cubeVAO: u32;
    gl.GenVertexArrays(1,&cubeVAO);
    gl.BindVertexArray(cubeVAO);


    cubeVBO : u32;
    gl.GenBuffers(1,&cubeVBO);

    
    //both light source and cube are cubes. We can re-use vertices
    gl.BindBuffer(gl.ARRAY_BUFFER,cubeVBO)
    gl.BufferData(gl.ARRAY_BUFFER,size_of(vertices),&vertices,gl.STATIC_DRAW)

    //Position data
    gl.VertexAttribPointer(0,3,gl.FLOAT,gl.FALSE, size_of(f32)*3, cast(uintptr)0)
    gl.EnableVertexAttribArray(0)


    lightVAO: u32;
    gl.GenVertexArrays(1,&lightVAO);
    gl.BindVertexArray(lightVAO);
    gl.VertexAttribPointer(0,3,gl.FLOAT,gl.FALSE, size_of(f32)*3, cast(uintptr)0)
    gl.EnableVertexAttribArray(0)


    gl.Enable(gl.DEPTH_TEST);

    // gl.UseProgram(shader_program);
    cube_program_id: u32; ok_cube: bool
    if cube_program_id, ok_cube = gl.load_shaders("./cube.vs", "./cube.fs"); !ok_cube {
        fmt.println("Failed to load shaders.")
        return
    }
    defer gl.DeleteProgram(cube_program_id)
    gl.UseProgram(cube_program_id);

    gl.Uniform3f(gl.GetUniformLocation(cube_program_id, "objectColor"), 1.0,0.5,0.3);
    gl.Uniform3f(gl.GetUniformLocation(cube_program_id, "lightColor"), 1.0,1.0,1.0);

    light_program_id: u32; ok_light: bool
    if light_program_id, ok_light = gl.load_shaders("./light.vs", "./light.fs"); !ok_light {
        fmt.println("Failed to load shaders.")
        return
    }
    defer gl.DeleteProgram(light_program_id)


    cubePosition := glm.vec3{ 0.0,  0.0,  0.0}
    lightPosition := glm.vec3{ 2.0,  5.0, -15.0}


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
        gl.ClearColor(0.1,0.1,0.1,1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);


        gl.UseProgram(cube_program_id);
        cube_model:= glm.mat4(1.0);
        cube_model_vec : glm.vec3 = {1,0,0};
        cube_model *= glm.mat4Rotate(cube_model_vec,glm.radians_f32(-55)); 
        cube_modelLoc := gl.GetUniformLocation(cube_program_id,"model");

        //This is part2
        //cube_rotate_vec : glm.vec3 = {0.5,1,0};
        //model *= glm.mat4Rotate(cube_rotate_vec, cast(f32)glfw.GetTime() * glm.radians_f32(50));

        gl.UniformMatrix4fv(cube_modelLoc, 1, gl.FALSE, &cube_model[0][0]);




        //view:= glm.mat4(1.0);
        //Note that we translate in the opposite direction that we want to move in
        cube_view_vec : glm.vec3 = {0,0,-3};
        camX := math.sin_f32(cast(f32)glfw.GetTime()) * radius;
        camZ := math.cos_f32(cast(f32)glfw.GetTime()) * radius;
        //view := glm.mat4LookAt(glm.vec3{camX,0,camZ},glm.vec3{0,0,0},glm.vec3{0,1,0});
        cube_view := glm.mat4LookAt(camera_pos,camera_pos + camera_front ,camera_up);
        cube_view *= glm.mat4Translate(cube_view_vec); 



        cube_viewLoc := gl.GetUniformLocation(cube_program_id,"view");
        gl.UniformMatrix4fv(cube_viewLoc, 1, gl.FALSE, &cube_view[0][0]);
        cube_projection:= glm.mat4(1.0);

        cube_projectionLoc := gl.GetUniformLocation(cube_program_id,"projection");
        cube_projection *= glm.mat4Perspective(glm.radians_f32(fov), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
        gl.UniformMatrix4fv(cube_projectionLoc, 1, gl.FALSE, &cube_projection[0][0]);

        gl.BindVertexArray(cubeVAO);
        cube_model *= glm.mat4Translate(cubePosition);
        gl.UniformMatrix4fv(cube_modelLoc, 1, gl.FALSE, &cube_model[0][0]);
        gl.DrawArrays(gl.TRIANGLES, 0, 36);


        gl.BindVertexArray(lightVAO);
        gl.UseProgram(light_program_id);
        light_model:= glm.mat4(1.0);
        light_model_vec : glm.vec3 = {1,0,0};
        //light_model *= glm.mat4Rotate(light_model_vec,glm.radians_f32(-55)); 
        light_modelLoc := gl.GetUniformLocation(light_program_id,"model");

        light_view:= glm.mat4(1.0);

        gl.UniformMatrix4fv(light_modelLoc, 1, gl.FALSE, &light_model[0][0]);



        light_viewLoc := gl.GetUniformLocation(light_program_id,"view");
        gl.UniformMatrix4fv(light_viewLoc, 1, gl.FALSE, &light_view[0][0]);
        light_projection:= glm.mat4(1.0);

        light_projectionLoc := gl.GetUniformLocation(light_program_id,"projection");
        light_projection *= glm.mat4Perspective(glm.radians_f32(fov), WINDOW_WIDTH / WINDOW_HEIGHT, 0.1, 100.0);
        gl.UniformMatrix4fv(light_projectionLoc, 1, gl.FALSE, &light_projection[0][0]);

        light_model *= glm.mat4Translate(lightPosition);
        light_rotate_vec : glm.vec3 = {0.5,1,0};
        light_model *= glm.mat4Rotate(light_rotate_vec, cast(f32)glfw.GetTime() * glm.radians_f32(50));

        gl.UniformMatrix4fv(light_modelLoc, 1, gl.FALSE, &light_model[0][0]);
        gl.DrawArrays(gl.TRIANGLES, 0, 36);




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

