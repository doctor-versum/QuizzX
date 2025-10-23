import asyncio
import websockets
import json

async def test_connection():
    try:
        # Test local connection
        uri = "ws://localhost:8765"
        print(f"Testing connection to {uri}")
        
        async with websockets.connect(uri) as websocket:
            print("Connected successfully!")
            
            # Send a test message
            test_message = {
                'type': 'connect',
                'mode': 'test'
            }
            await websocket.send(json.dumps(test_message))
            print("Sent test message")
            
            # Wait for response
            response = await websocket.recv()
            print(f"Received: {response}")
            
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_connection()) 