
import numpy as np
import cv2

# Define the input video file path
video_file = 'display8x4/loading.mp4'
outputfilepath = 'data.lua'

# Open the video file
video_capture = cv2.VideoCapture(video_file)

# Define a function to determine if a pixel is black based on a threshold
def is_black(pixel, threshold=50):
    return all(value < threshold for value in pixel)

# Initialize an empty list to store frames
frames_list = []

while True:
    # Read a frame from the video
    ret, frame = video_capture.read()

    if not ret:
        break  # Break the loop if we've reached the end of the video

    # Resize the frame to 8x4
    frame = cv2.resize(frame, (8, 4))

    # Convert the frame to a binary array (1/0) based on blackness
    frame_binary = [[1 if is_black(frame[j][i]) else 0 for i in range(8)] for j in range(4)]

    # Append the binary frame to the list
    frames_list.append(frame_binary)

# Release the video capture object
video_capture.release()

# Continue with the Lua array generation and saving as in your original script
def python_to_lua_array(arr):
    lua_array = "{\n"
    for frame in arr:
        lua_array += "    {\n"
        for row in frame:
            lua_array += "        {"
            lua_array += ", ".join(map(str, row))
            lua_array += "},\n"
        lua_array += "    },\n"
    lua_array += "}\n"
    return lua_array

lua_code = python_to_lua_array(frames_list)

# Write the Lua code to a file
with open(outputfilepath, 'w') as lua_file:
    lua_file.write(lua_code)

print("Lua array saved to data.lua")
