import numpy as np
import cv2

# Define the input video file path
video_file = 'display8x4/resized_loading.mp4'
outputfilepath = 'data.lua'

# Open the video file
video_capture = cv2.VideoCapture(video_file)

# Initialize an empty list to store frames
frames_list = []

while True:
    # Read a frame from the video
    ret, frame = video_capture.read()

    if not ret:
        break  # Break the loop if we've reached the end of the video

    # Resize the frame to 8x4
    frame = cv2.resize(frame, (4, 8))

    # Convert the frame to a binary array (true/false) based on darkness
    frame_binary = frame < 50  # Invert the condition

    # Append the binary frame to the list
    frames_list.append(frame_binary)

    #cv2.imshow('Video', frame)  # Display the frame

# Release the video capture object
video_capture.release()

# Convert the list of frames to a NumPy array
frames_array = np.array(frames_list)

# Continue with the Lua array generation and saving as in your original script
def python_to_lua_array(arr):
    lua_array = "{\n"
    for frame in arr:
        lua_array += "    {\n"
        for row in frame:
            lua_array += "        {"
            lua_array += ", ".join(map(lambda x: "true" if x.any() else "false", row))
            lua_array += "},\n"
        lua_array += "    },\n"
    lua_array += "}\n"
    return lua_array

lua_code = python_to_lua_array(frames_array)

# Write the Lua code to a file
with open(video_file, 'w') as lua_file:
    lua_file.write(lua_code)

print("Lua array saved to data.lua")
