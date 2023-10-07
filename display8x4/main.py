import numpy as np

# Define the dimensions of the animation (8x4 pixels)
width, height = 8, 4

def array_to_lua(arr, filename):
    # Convert the Python array to a Lua array format
    def python_to_lua_array(arr):
        lua_array = "{\n"
        for row in arr:
            lua_array += "    {"
            lua_array += ", ".join(map(lambda x: "true" if x else "false", row))
            lua_array += "},\n"
        lua_array += "}\n"
        return lua_array

    lua_code = python_to_lua_array(arr)

    # Write the Lua code to the specified file
    with open(filename, 'w') as lua_file:
        lua_file.write(lua_code)

    print(f"Lua array saved to {filename}")

def main():
    print("Hello World!")
    frame = np.random.choice([True, False], size=(height, width))
    array_to_lua(frame, "frame.lua")
    



if __name__ == "__main__":
    main()

