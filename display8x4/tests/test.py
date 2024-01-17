import cv2

# Implement and test the new script

# Define a function to determine if a pixel is black based on a threshold
def is_black(pixel, threshold=50):
    return all(value < threshold for value in pixel)

# Open the video file
video_file = 'display8x4/loading.mp4'
video_capture = cv2.VideoCapture(video_file)

# Initialize an empty list to store frames
frames_list = []

while True:
    # Read a frame from the video
    ret, frame = video_capture.read()
    if not ret:
        break

    # Resize the frame to 8x4
    frame = cv2.resize(frame, (8, 4))

    # Convert the frame to a binary array (true/false) based on blackness
    frame_binary = [[True if is_black(frame[j][i]) else False for i in range(8)] for j in range(4)]
    frames_list.append(frame_binary)

# Release the video capture object
video_capture.release()

# Convert Python frames list to Lua table format
def python_to_lua_array(arr):
    lua_array = "return {\\n"
    for frame in arr:
        lua_array += "    {\\n"
        for row in frame:
            lua_array += "        {"
            lua_array += ", ".join(["true" if pixel else "false" for pixel in row])
            lua_array += "},\\n"
        lua_array += "    },\\n"
    lua_array += "}\\n"
    return lua_array

lua_output = python_to_lua_array(frames_list)

# Checking the initial section of the generated Lua array
print(lua_output[:500])  # Displaying the first 500 characters for verification
