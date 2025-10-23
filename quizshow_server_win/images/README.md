# Images Directory

This directory contains local images that can be used in image slides.

## Usage

To use a local image in your quiz show:

1. Place your image file in this directory (e.g., `sample.jpg`)
2. In your `config.jsonc`, create an image page like this:

```json
{
  "img1": {
    "type": "image",
    "image": "images/sample.jpg",
    "text": "Your text overlay here"
  }
}
```

## Supported Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)
- And other common image formats

## File Paths

- Use relative paths from the server directory
- Example: `images/photo.jpg` (not `/images/photo.jpg`)
- Subdirectories are supported: `images/category/photo.jpg`

## Security

- Only files in the server directory and subdirectories are accessible
- Path traversal attacks (../) are blocked
- Files outside the server directory cannot be accessed

## Server URLs

The server automatically converts local paths to accessible URLs:
- Local path: `images/sample.jpg`
- Server URL: `http://[server-ip]:8080/static/images/sample.jpg`

The server will automatically use the correct IP address based on the client's connection.
