from PIL import Image

def bitmap_to_mem_file(output_file='letters.mem'):
    """
    Convert 26 letter bitmaps to a single .mem file for Verilog
    Assumes files are named A.bmp, B.bmp, ..., Z.bmp
    """
    with open(output_file, 'w') as f:
        for letter in 'abcdefghijklmnopqrstuvwxyz':
            img_path = f'{letter}.png'
            
            try:
                # Open and convert to 1-bit (black and white)
                img = Image.open(img_path).convert('1')
                width, height = img.size
                
                print(f"Processing {letter}.bmp ({width}x{height})")
                
                # Make sure it's 48x48
                if width != 48 or height != 48:
                    print(f"Warning: {letter}.bmp is {width}x{height}, resizing to 48x48")
                    img = img.resize((48, 48), Image.NEAREST)
                
                # Write each pixel as a line in the .mem file
                for y in range(48):
                    for x in range(48):
                        pixel = img.getpixel((x, y))
                        # pixel is 0 (black) or 255 (white) after convert('1')
                        # We want: 1 = draw letter (black), 0 = transparent (white)
                        f.write('1\n' if pixel == 255 else '0\n')
                        
            except FileNotFoundError:
                print(f"Error: Could not find {img_path}")
                # Write blank letter (all zeros)
                for i in range(48 * 48):
                    f.write('0\n')
    
    print(f"\nGenerated {output_file} with {26 * 48 * 48} pixels")

# Run it
bitmap_to_mem_file('letters.mem')