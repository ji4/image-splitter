# Image Splitter for AI Upload

A bash script that automatically splits large images into smaller parts to meet the size and dimension requirements for uploading to AI platforms like Claude or GPT. This tool is especially useful when working with images that exceed the standard upload limitations.

## Claude Image Upload Limitations

This script is specifically designed to address Claude's image upload limitations:
- Maximum file size: 30MB
- Maximum dimensions: 8000x8000 pixels
- Recommended minimum dimensions: 1000x1000 pixels

When images exceed these limitations, this script will automatically split them into appropriate sizes while providing instructions for AI models to process them as a single image.

## Requirements

This script requires ImageMagick to be installed on your system. If you don't have it installed, you'll receive an error message. Install it using one of the following commands depending on your operating system:

```bash
# For Ubuntu/Debian
sudo apt-get install imagemagick

# For macOS
brew install imagemagick

# For CentOS/RHEL
sudo yum install imagemagick
```

## Features

- Automatically detects if an image needs to be split based on Claude's limitations (>30MB or >8000x8000 pixels)
- Intelligently determines the optimal splitting direction (horizontal or vertical) based on the image's aspect ratio
- Supports user-defined number of splits
- Provides a prompt template to use when uploading the split images to AI platforms
- Keeps all output files in the same directory as the original image

## Usage

### Basic Usage

First, make the script executable:

```bash
chmod +x image-splitter.sh
```

To process an image with automatic splitting:

```bash
./image-splitter.sh /path/to/your/image.jpg
```

### Specifying Split Count

To split an image into a specific number of parts:

```bash
./image-splitter.sh /path/to/your/image.jpg 2
```

This example splits the image into 2 equal parts.

## How It Works

The script follows these steps:

1. Checks if the image exceeds Claude's upload limits (30MB file size or 8000x8000 pixels)
2. Determines whether to split horizontally or vertically based on which dimension is larger
3. Calculates how many splits are needed (if not specified by the user)
4. Performs the image splitting operation using ImageMagick
5. Generates a prompt template to instruct the AI how to reassemble the image

## Examples

### Example 1: Automatic Splitting

```bash
./image-splitter.sh large_panorama.jpg
```

Output:
```
Image information:
  Filename: large_panorama.jpg
  Dimensions: 12000x3000 pixels
  File size: 35.5MB
  Color depth: 8-bit

Need to split image: File size exceeds 30MB limit
Will split image into 2 parts, split direction: horizontal

Generated split file: large_panorama_part1.jpg
Generated split file: large_panorama_part2.jpg

Prompt content:
This is a split image with 2 parts. Please analyze them as a single image.
Split direction: horizontal (width direction was split)
Original image dimensions: 12000x3000 pixels
Please join these images in the horizontal direction for analysis.

Image processing complete! Split into 2 parts.
```

### Visual Representation of Splitting

Original image:
```
┌───────────────────────────────────┐
│                                   │
│                                   │
│            LARGE IMAGE            │
│                                   │
│                                   │
└───────────────────────────────────┘
```

Horizontal split (width direction):
```
┌───────────────┐ ┌───────────────┐
│               │ │               │
│               │ │               │
│   PART 1      │ │   PART 2      │
│               │ │               │
│               │ │               │
└───────────────┘ └───────────────┘
```

Vertical split (height direction):
```
┌───────────────────────────────────┐
│                                   │
│             PART 1                │
│                                   │
└───────────────────────────────────┘
┌───────────────────────────────────┐
│                                   │
│             PART 2                │
│                                   │
└───────────────────────────────────┘
```

## Troubleshooting

### Common errors:

1. **"Error: This script requires ImageMagick"**
   - Install ImageMagick using the commands provided in the Requirements section.

2. **"Error: Cannot find image 'path/to/image'"**
   - Check that the file path is correct and the image exists.

3. **Permission denied**
   - Make sure the script is executable: `chmod +x image-splitter.sh`

## Notes

- Split images will be named with the pattern: `[original_filename]_part[number].[extension]`
- The script works best with common image formats (JPG, PNG, GIF, etc.)
- Very large images may take some time to process
- The minimum recommended dimension for AI image analysis is 1000x1000 pixels