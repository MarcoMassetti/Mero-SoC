import sys

def binary_to_ascii_text(input_file, output_file):
    with open(input_file, 'rb') as bin_file:
        # Read the entire binary file
        binary_data = bin_file.read()

    # Prepare to store the binary string
    binary_string = ''

    # Process the binary data in 4-byte (32-bit) chunks
    for i in range(0, len(binary_data), 4):
        chunk = binary_data[i:i + 4]
        # Reverse the order of bytes in the chunk for endianness
        reversed_chunk = chunk[::-1]
        # Convert the reversed chunk to a string of '1's and '0's
        binary_string += ''.join(format(byte, '08b') for byte in reversed_chunk)

    # Split the binary string into chunks of 32 bits
    chunks = [binary_string[i:i + 32] for i in range(0, len(binary_string), 32)]

    # Write the chunks to the output text file
    with open(output_file, 'w') as text_file:
        for chunk in chunks:
            text_file.write(chunk + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python binary_to_text.py <input_file> <output_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    binary_to_ascii_text(input_file, output_file)
