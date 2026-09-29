import os
from PIL import Image

def process_icon():
    icon_path = 'assets/images/tripromio_icon.jpg'
    output_path = 'assets/images/tripromio_icon_foreground.png'
    
    img = Image.open(icon_path).convert('RGBA')
    width, height = img.size
    
    # Get top-left pixel color to use as padding
    bg_color = img.getpixel((0, 0))
    print(f"Detected background color: {bg_color}")
    
    # Create a new square canvas (let's use 1024x1024)
    canvas_size = 1024
    canvas = Image.new('RGBA', (canvas_size, canvas_size), bg_color)
    
    # Calculate scale so the original image fits nicely in the safe zone.
    # Adaptive icons have a 108dp canvas and 66dp safe zone (66/108 = 61%)
    # Let's scale the original image to 60% of the canvas.
    scale_factor = 0.60
    new_size = int(canvas_size * scale_factor)
    
    # Resize original image
    resized_img = img.resize((new_size, new_size), Image.Resampling.LANCZOS)
    
    # Calculate position to center
    offset = (canvas_size - new_size) // 2
    
    # Paste resized image onto canvas
    canvas.paste(resized_img, (offset, offset))
    
    # Save
    canvas.save(output_path, 'PNG')
    print(f"Saved padded icon to {output_path}")

    # Write a hex color for the pubspec
    r, g, b, a = bg_color
    hex_color = f"#{r:02x}{g:02x}{b:02x}"
    print(f"Hex color for background: {hex_color}")

if __name__ == '__main__':
    process_icon()
