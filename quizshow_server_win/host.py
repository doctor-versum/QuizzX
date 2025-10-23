import asyncio
import websockets
import json
import logging
from datetime import datetime
from typing import Dict, Set
import json5  # For parsing JSONC files
from aiohttp import web
from aiohttp_cors import setup, ResourceOptions
import os
import mimetypes

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class QuizShowServer:
    def __init__(self):
        self.clients: Dict[str, websockets.WebSocketServerProtocol] = {}
        self.client_info: Dict[str, dict] = {}
        self.config = self.load_config()
        self.active_timers: Dict[str, asyncio.Task] = {}
        self.pressed_buttons = set()  # Track pressed buttons for page 0
        self.last_render_command = None  # Track the last render command sent to all clients
        
        # Team management
        self.team_points = {'team_red': 0, 'team_blue': 0, 'team_yellow': 0, 'team_green': 0}
        self.enabled_team = 'team_red'  # Which team can press buttons
        self.last_buzzer_team = None  # Last team to press buzzer
        self.global_current_page = '0'  # Track global current page
        
    def load_config(self):
        """Load the config.jsonc file"""
        try:
            with open('config.jsonc', 'r', encoding='utf-8') as f:
                config = json5.loads(f.read())
                # Process config to convert local image paths to server URLs
                return self.process_config_for_client(config)
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            return {}
    
    def process_config_for_client(self, config, client_ip=None):
        """Process config to convert local image paths to server URLs"""
        processed_config = {}
        for page_id, page_config in config.items():
            processed_page = page_config.copy()
            
            # If this is an image page, process the image URL
            if page_config.get('type') == 'image' and 'image' in page_config:
                image_path = page_config['image']
                
                # Check if it's a local file path (not a URL)
                if not image_path.startswith(('http://', 'https://', 'data:')):
                    # Use client IP if available, otherwise use localhost
                    if client_ip and client_ip != 'unknown':
                        server_url = f"http://{client_ip}:8080/static/{image_path}"
                    else:
                        server_url = f"http://localhost:8080/static/{image_path}"
                    processed_page['image'] = server_url
                    logger.info(f"Converted local image path '{image_path}' to server URL '{server_url}'")
            
            processed_config[page_id] = processed_page
        
        return processed_config
        
    async def register_client(self, websocket):
        """Register a new client connection"""
        try:
            client_id = f"client_{len(self.clients) + 1}"
            self.clients[client_id] = websocket
            self.client_info[client_id] = {
                'connected_at': datetime.now().isoformat(),
                'mode': None,
                'ip': websocket.remote_address[0] if websocket.remote_address else 'unknown'
            }
            
            logger.info(f"Client {client_id} connected from {self.client_info[client_id]['ip']}")
            
            # Send welcome message
            await websocket.send(json.dumps({
                'type': 'welcome',
                'client_id': client_id,
                'message': 'Connected to Quiz Show Server'
            }))
            
            try:
                async for message in websocket:
                    await self.handle_message(client_id, message)
            except websockets.exceptions.ConnectionClosed:
                logger.info(f"Client {client_id} disconnected")
            finally:
                await self.unregister_client(client_id)
        except Exception as e:
            logger.error(f"Error in register_client: {e}")
            raise
    
    async def unregister_client(self, client_id):
        """Unregister a client when they disconnect"""
        websocket = self.clients.get(client_id)
        if websocket:
            try:
                await websocket.close()
            except Exception as e:
                logger.debug(f"Error closing websocket for {client_id}: {e}")
        self.clients.pop(client_id, None)
        self.client_info.pop(client_id, None)
        logger.info(f"Client {client_id} unregistered")
    
    async def handle_message(self, client_id, message):
        """Handle incoming messages from clients"""
        try:
            data = json.loads(message)
            message_type = data.get('type')
            
            logger.info(f"Received message from {client_id}: {message_type}")
            
            if message_type == 'connect':
                # Handle connection request with mode
                mode = data.get('mode')
                self.client_info[client_id]['mode'] = mode
                
                logger.info(f"Client {client_id} connected as {mode}")
                
                # Send confirmation
                await self.clients[client_id].send(json.dumps({
                    'type': 'connection_confirmed',
                    'mode': mode,
                    'client_id': client_id
                }))
                
                # Send config to client with processed image URLs
                client_ip = self.client_info[client_id]['ip']
                processed_config = self.process_config_for_client(self.config, client_ip)
                await self.clients[client_id].send(json.dumps({
                    'type': 'config',
                    'config': processed_config
                }))
                
                # Send the last render command if available, otherwise default to page 0
                if self.last_render_command:
                    await self.clients[client_id].send(json.dumps(self.last_render_command))
                    # Update client's current page based on the last render command
                    self.client_info[client_id]['current_page'] = self.last_render_command['page_id']
                    # Update global current page
                    self.global_current_page = self.last_render_command['page_id']
                else:
                    # Default to page 0 if no previous render command
                    await self.clients[client_id].send(json.dumps({
                        'type': 'render_page',
                        'page_id': '0',
                        'pressed_buttons': list(self.pressed_buttons)
                    }))
                    self.client_info[client_id]['current_page'] = '0'
                    # Update global current page
                    self.global_current_page = '0'
                
                # Broadcast to other clients about new connection
                await self.broadcast_to_others(client_id, {
                    'type': 'client_connected',
                    'client_id': client_id,
                    'mode': mode
                })
                
            elif message_type == 'reconnect':
                # Handle reconnection request
                mode = data.get('mode')
                self.client_info[client_id]['mode'] = mode
                
                logger.info(f"Client {client_id} reconnected as {mode}")
                
                # Send confirmation
                await self.clients[client_id].send(json.dumps({
                    'type': 'connection_confirmed',
                    'mode': mode,
                    'client_id': client_id
                }))
                
                # Send config to client with processed image URLs
                client_ip = self.client_info[client_id]['ip']
                processed_config = self.process_config_for_client(self.config, client_ip)
                await self.clients[client_id].send(json.dumps({
                    'type': 'config',
                    'config': processed_config
                }))
                
                # Send the last render command if available, otherwise default to page 0
                if self.last_render_command:
                    await self.clients[client_id].send(json.dumps(self.last_render_command))
                else:
                    # Default to page 0 if no previous render command
                    await self.clients[client_id].send(json.dumps({
                        'type': 'render_page',
                        'page_id': '0',
                        'pressed_buttons': list(self.pressed_buttons)
                    }))
                
            elif message_type == 'ping':
                # Handle ping messages
                await self.clients[client_id].send(json.dumps({
                    'type': 'pong',
                    'timestamp': datetime.now().isoformat()
                }))
                
            elif message_type == 'get_clients':
                # Send list of connected clients
                clients_list = []
                for cid, info in self.client_info.items():
                    if cid != client_id:  # Don't include self
                        clients_list.append({
                            'client_id': cid,
                            'mode': info['mode'],
                            'connected_at': info['connected_at'],
                            'ip': info['ip']
                        })
                
                await self.clients[client_id].send(json.dumps({
                    'type': 'clients_list',
                    'clients': clients_list
                }))
                
            elif message_type == 'grid_click':
                # Handle grid click with coordinates
                row = data.get('row')
                col = data.get('col')
                logger.info(f"Grid click from {client_id}: row={row}, col={col}")
                
                # Get the current page from client info
                current_page = self.client_info[client_id].get('current_page', '0')
                page_config = self.config.get(current_page, {})
                
                if page_config.get('type') == 'main':
                    table = page_config.get('table', [])
                    # IMPORTANT:
                    # config.table is column-major: table[col][row]
                    # Client sends (row, col). We must access table[col][row].
                    if col < len(table) and row < len(table[col]):
                        # Normalize button key to preserve existing format (row_col)
                        button_key = f"{row}_{col}"
                        if button_key in self.pressed_buttons:
                            logger.info(f"Button {button_key} already pressed, ignoring")
                            return

                        # Mark button as pressed
                        self.pressed_buttons.add(button_key)
                        logger.info(f"Button {button_key} marked as pressed")

                        # Auto-disable both teams after button press by enabled team
                        if self.client_info[client_id].get('mode') == self.enabled_team:
                            self.enabled_team = 'none'
                            logger.info(f"Auto-disabled both teams after button press by {self.client_info[client_id].get('mode')}")

                        # Access the correct cell (column-major)
                        cell = table[col][row]
                        link_page = cell.get('link')

                        if link_page and link_page in self.config:
                            # Cancel any active timer for the current page before switching
                            if current_page in self.active_timers:
                                self.active_timers[current_page].cancel()
                                del self.active_timers[current_page]
                                logger.info(f"Cancelled timer for page {current_page} due to grid click")
                            
                            render_command = {
                                'type': 'render_page',
                                'page_id': link_page,
                                'page_config': self.config[link_page]
                            }
                            self.last_render_command = render_command.copy()
                            await self.broadcast_to_all(render_command)

                            # Update all clients' current page
                            for cid in self.client_info:
                                self.client_info[cid]['current_page'] = link_page
                            self.global_current_page = link_page

                            # Start server-side timer if the new page is a timer
                            new_page_config = self.config.get(link_page, {})
                            if new_page_config.get('type') == 'timer':
                                await self.start_server_timer(link_page, new_page_config)

                            logger.info(f"All clients switched to page {link_page}")
                        else:
                            logger.warning(f"Invalid link page: {link_page}")

                        # If teams were auto-disabled, broadcast the updated state
                        if self.enabled_team == 'none':
                            if self.last_render_command:
                                updated_render_command = self.last_render_command.copy()
                                if updated_render_command.get('page_id') == '0':
                                    updated_render_command['pressed_buttons'] = list(self.pressed_buttons)
                                    updated_render_command['enabled_team'] = self.enabled_team
                                await self.broadcast_to_all(updated_render_command)
                                logger.info("Broadcasted disabled state to all clients")
                            
            elif message_type == 'buzzer_press':
                # Handle buzzer press
                team_mode = self.client_info[client_id].get('mode', 'unknown')
                current_page = self.client_info[client_id].get('current_page', '0')
                page_config = self.config.get(current_page, {})
                
                # Track last buzzer team
                self.last_buzzer_team = team_mode
                
                logger.info(f"Buzzer pressed by {team_mode} team ({client_id}) on page {current_page}")
                
                # Get the linked page from the buzzer page
                link_page = page_config.get('link')
                
                if link_page and link_page in self.config:
                    # Cancel any active timer for the current page before switching
                    if current_page in self.active_timers:
                        self.active_timers[current_page].cancel()
                        del self.active_timers[current_page]
                        logger.info(f"Cancelled timer for page {current_page} due to buzzer press")
                    
                    # Create render command
                    render_command = {
                        'type': 'render_page',
                        'page_id': link_page,
                        'page_config': self.config[link_page]
                    }
                    
                    # Store as last render command
                    self.last_render_command = render_command.copy()
                    
                    # Send render command to ALL clients
                    await self.broadcast_to_all(render_command)
                    
                    # Update all clients' current page
                    for cid in self.client_info:
                        self.client_info[cid]['current_page'] = link_page
                    # Update global current page
                    self.global_current_page = link_page
                    
                    # Start server-side timer if the new page is a timer
                    new_page_config = self.config.get(link_page, {})
                    if new_page_config.get('type') == 'timer':
                        await self.start_server_timer(link_page, new_page_config)
                        
                    logger.info(f"All clients switched to page {link_page}")
                else:
                    logger.warning(f"Invalid link page for buzzer: {link_page}")
                    
            elif message_type == 'timer_finished':
                # Handle timer finished from client
                current_page = self.client_info[client_id].get('current_page', '0')
                page_config = self.config.get(current_page, {})
                
                logger.info(f"Timer finished for {client_id} on page {current_page}")
                logger.info(f"Page config: {page_config}")
                
                # Cancel any active timer for this page
                if current_page in self.active_timers:
                    self.active_timers[current_page].cancel()
                    del self.active_timers[current_page]
                
                # Get the linked page from the timer page
                link_page = page_config.get('link')
                logger.info(f"Link page from config: {link_page}")
                
                if link_page and link_page in self.config:
                    # Create render command
                    render_command = {
                        'type': 'render_page',
                        'page_id': link_page,
                        'page_config': self.config[link_page]
                    }
                    
                    # Store as last render command
                    self.last_render_command = render_command.copy()
                    
                    # Send render command to ALL clients
                    await self.broadcast_to_all(render_command)
                    
                    # Update all clients' current page
                    for cid in self.client_info:
                        self.client_info[cid]['current_page'] = link_page
                    # Update global current page
                    self.global_current_page = link_page
                    
                    # Start server-side timer if the new page is a timer
                    new_page_config = self.config.get(link_page, {})
                    if new_page_config.get('type') == 'timer':
                        await self.start_server_timer(link_page, new_page_config)
                        
                    logger.info(f"All clients switched to page {link_page}")
                else:
                    logger.warning(f"Invalid link page for timer: {link_page}")
                
            elif message_type == 'master_add_points':
                team = data.get('team')
                points = data.get('points', 1)
                if team in self.team_points:
                    self.team_points[team] += points
                    logger.info(f"Added {points} points to {team}, total: {self.team_points[team]}")
                    
            elif message_type == 'master_remove_points':
                team = data.get('team')
                points = data.get('points', 1)
                if team in self.team_points:
                    self.team_points[team] = max(0, self.team_points[team] - points)
                    logger.info(f"Removed {points} points from {team}, total: {self.team_points[team]}")
                    
            elif message_type == 'master_enable_team':
                team = data.get('team')
                if team in ['team_red', 'team_blue', 'team_yellow', 'team_green', 'none']:
                    self.enabled_team = team
                    logger.info(f"Enabled team: {team}")
                    
                    # Broadcast the current page with updated enabled team to all clients
                    if self.last_render_command:
                        # Send the last render command with updated enabled team
                        updated_render_command = self.last_render_command.copy()
                        if updated_render_command.get('page_id') == '0':
                            # For page 0, include pressed buttons and enabled team
                            updated_render_command['pressed_buttons'] = list(self.pressed_buttons)
                            updated_render_command['enabled_team'] = self.enabled_team
                        await self.broadcast_to_all(updated_render_command)
                        logger.info(f"Broadcasted updated render command with enabled team: {team}")
                    else:
                        # If no last render command, send page 0 with current state
                        render_command = {
                            'type': 'render_page',
                            'page_id': '0',
                            'page_config': self.config['0'],
                            'pressed_buttons': list(self.pressed_buttons),
                            'enabled_team': self.enabled_team
                        }
                        await self.broadcast_to_all(render_command)
                        logger.info(f"Broadcasted page 0 with enabled team: {team}")
                    
            elif message_type == 'master_reset':
                self.team_points = {'team_red': 0, 'team_blue': 0, 'team_yellow': 0, 'team_green': 0}
                self.enabled_team = 'team_red'
                self.last_buzzer_team = None
                self.pressed_buttons.clear()
                logger.info("Reset all game state")
                
                # Broadcast the reset state to all clients
                render_command = {
                    'type': 'render_page',
                    'page_id': '0',
                    'page_config': self.config['0'],
                    'pressed_buttons': list(self.pressed_buttons),
                    'enabled_team': self.enabled_team
                }
                await self.broadcast_to_all(render_command)
                logger.info("Broadcasted reset state to all clients")
                
            elif message_type == 'next_slide':
                # Use the global current page
                current_page = self.global_current_page
                page_config = self.config.get(current_page, {})
                link_page = page_config.get('link')
                
                # Cancel any active timer for the current page before switching
                if current_page in self.active_timers:
                    self.active_timers[current_page].cancel()
                    del self.active_timers[current_page]
                    logger.info(f"Cancelled timer for page {current_page} due to next slide")
                
                if link_page and link_page in self.config:
                    # Create render command
                    render_command = {
                        'type': 'render_page',
                        'page_id': link_page,
                        'page_config': self.config[link_page]
                    }
                    
                    # Store as last render command
                    self.last_render_command = render_command.copy()
                    
                    # Send render command to ALL clients
                    await self.broadcast_to_all(render_command)
                    
                    # Update all clients' current page
                    for cid in self.client_info:
                        self.client_info[cid]['current_page'] = link_page
                    # Update global current page
                    self.global_current_page = link_page
                    
                    # Start server-side timer if the new page is a timer
                    new_page_config = self.config.get(link_page, {})
                    if new_page_config.get('type') == 'timer':
                        await self.start_server_timer(link_page, new_page_config)
                        
                    logger.info(f"Next slide: All clients switched to page {link_page}")
                else:
                    logger.warning(f"Invalid link page for next slide: {link_page}")
                    
            elif message_type == 'return_to_main':
                # Cancel any active timer for the current page before switching to main
                current_page = self.global_current_page
                if current_page in self.active_timers:
                    self.active_timers[current_page].cancel()
                    del self.active_timers[current_page]
                    logger.info(f"Cancelled timer for page {current_page} due to return to main")
                
                # Create render command for page 0
                render_command = {
                    'type': 'render_page',
                    'page_id': '0',
                    'page_config': self.config['0'],
                    'pressed_buttons': list(self.pressed_buttons),
                    'enabled_team': self.enabled_team
                }
                
                # Store as last render command
                self.last_render_command = render_command.copy()
                
                # Send render command to ALL clients
                await self.broadcast_to_all(render_command)
                
                # Update all clients' current page
                for cid in self.client_info:
                    self.client_info[cid]['current_page'] = '0'
                # Update global current page
                self.global_current_page = '0'
                    
                logger.info(f"Return to main: All clients switched to page 0 (pressed buttons: {list(self.pressed_buttons)})")
                
            else:
                logger.warning(f"Unknown message type: {message_type}")
                
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON from client {client_id}: {e}")
            raise
        except Exception as e:
            logger.error(f"Error handling message from client {client_id}: {e}")
            raise
    
    async def start_server_timer(self, page_id, page_config):
        """Start a server-side timer for a timer page"""
        time_seconds = page_config.get('time', 0)
        if time_seconds <= 0:
            return
            
        # Cancel any existing timer for this page
        if page_id in self.active_timers:
            self.active_timers[page_id].cancel()
            
        logger.info(f"Starting server timer for page {page_id}: {time_seconds} seconds")
        
        async def timer_task():
            try:
                await asyncio.sleep(time_seconds)
                
                # Timer finished - send render command to all clients
                link_page = page_config.get('link')
                logger.info(f"Server timer finished for page {page_id}, link_page: {link_page}")
                if link_page and link_page in self.config:
                    # Create render command
                    render_command = {
                        'type': 'render_page',
                        'page_id': link_page,
                        'page_config': self.config[link_page]
                    }
                    
                    # Store as last render command
                    self.last_render_command = render_command.copy()
                    
                    await self.broadcast_to_all(render_command)
                    
                    # Update all clients' current page
                    for cid in self.client_info:
                        self.client_info[cid]['current_page'] = link_page
                    # Update global current page
                    self.global_current_page = link_page
                        
                    logger.info(f"Server timer finished for page {page_id}, all clients switched to page {link_page}")
                else:
                    logger.warning(f"Invalid link page for server timer: {link_page}")
                    
            except asyncio.CancelledError:
                logger.info(f"Server timer for page {page_id} was cancelled")
            finally:
                # Remove from active timers
                if page_id in self.active_timers:
                    del self.active_timers[page_id]
        
        # Start the timer task
        self.active_timers[page_id] = asyncio.create_task(timer_task())
    
    async def broadcast_to_others(self, sender_id, message):
        """Broadcast message to all clients except sender"""
        disconnected_clients = []
        for client_id, websocket in self.clients.items():
            if client_id != sender_id:
                try:
                    await websocket.send(json.dumps(message))
                except websockets.exceptions.ConnectionClosed:
                    # Mark for removal
                    disconnected_clients.append(client_id)
        
        # Remove disconnected clients after iteration
        for client_id in disconnected_clients:
            await self.unregister_client(client_id)
    
    async def broadcast_to_all(self, message):
        """Broadcast message to all connected clients"""
        disconnected_clients = []
        for client_id, websocket in self.clients.items():
            try:
                # If rendering page 0, include pressed buttons and team state
                if message.get('type') == 'render_page' and message.get('page_id') == '0':
                    message_with_buttons = message.copy()
                    message_with_buttons['pressed_buttons'] = list(self.pressed_buttons)
                    message_with_buttons['enabled_team'] = self.enabled_team
                    await websocket.send(json.dumps(message_with_buttons))
                else:
                    await websocket.send(json.dumps(message))
            except websockets.exceptions.ConnectionClosed:
                disconnected_clients.append(client_id)
        
        # Clean up disconnected clients
        for client_id in disconnected_clients:
            await self.unregister_client(client_id)
    
    def get_server_info(self):
        """Get server information"""
        return {
            'total_clients': len(self.clients),
            'clients': self.client_info,
            'server_time': datetime.now().isoformat()
        }

async def main():
    server = QuizShowServer()
    
    # Create a proper handler function
    async def handler(websocket):
        await server.register_client(websocket)
    
    # HTTP server for points
    async def points_handler(request):
        # Count devices for each team
        team_red_devices = sum(1 for info in server.client_info.values() if info.get('mode') == 'team_red')
        team_blue_devices = sum(1 for info in server.client_info.values() if info.get('mode') == 'team_blue')
        team_yellow_devices = sum(1 for info in server.client_info.values() if info.get('mode') == 'team_yellow')
        team_green_devices = sum(1 for info in server.client_info.values() if info.get('mode') == 'team_green')
        
        return web.json_response({
            'team_red': server.team_points['team_red'],
            'team_blue': server.team_points['team_blue'],
            'team_yellow': server.team_points['team_yellow'],
            'team_green': server.team_points['team_green'],
            'enabled_team': server.enabled_team,
            'last_buzzer_team': server.last_buzzer_team,
            'team_red_devices': team_red_devices,
            'team_blue_devices': team_blue_devices,
            'team_yellow_devices': team_yellow_devices,
            'team_green_devices': team_green_devices
        })
    
    # Create HTTP app
    app = web.Application()
    app.router.add_get('/points', points_handler)
    
    # Add static file handler for local images
    async def static_handler(request):
        # Get the file path from the URL
        file_path = request.match_info['path']
        
        # Security check - only allow files in the current directory or subdirectories
        if '..' in file_path or file_path.startswith('/'):
            return web.Response(status=403, text='Forbidden')
        
        # Construct full path
        full_path = os.path.join(os.getcwd(), file_path)
        
        # Check if file exists
        if not os.path.exists(full_path) or not os.path.isfile(full_path):
            return web.Response(status=404, text='File not found')
        
        # Get MIME type
        mime_type, _ = mimetypes.guess_type(full_path)
        if not mime_type:
            mime_type = 'application/octet-stream'
        
        # Read and return file
        with open(full_path, 'rb') as f:
            content = f.read()
        
        return web.Response(
            body=content,
            content_type=mime_type,
            headers={
                'Cache-Control': 'public, max-age=3600',  # Cache for 1 hour
            }
        )
    
    # Add route for static files
    app.router.add_get('/static/{path:.*}', static_handler)

    cors = setup(app, defaults={
        "*": ResourceOptions(
            allow_credentials=True,
            expose_headers="*",
            allow_headers="*",
        )
    })

    for route in list(app.router.routes()):
        cors.add(route)
    
    # Start HTTP server
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8080)
    await site.start()
    logger.info("HTTP server started on http://0.0.0.0:8080/points")
    
    # Start WebSocket server
    start_server = websockets.serve(
        handler,
        "0.0.0.0",  # Listen on all interfaces
        8765,
        ping_interval=20,
        ping_timeout=10
    )
    
    logger.info("Starting Quiz Show Server on ws://0.0.0.0:8765")
    logger.info("Press Ctrl+C to stop the server")
    
    try:
        await start_server
        await asyncio.Future()  # Run forever
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
