import json
from channels.generic.websocket import AsyncWebsocketConsumer
from time import time

class ChatConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        qs = self.scope["query_string"].decode()
        params = dict(x.split("=") for x in qs.split("&") if "=" in x)

        self.chat_id = params.get("chatId")
        self.author_id = params.get("authorId")

        self.room_group_name = f"chat_{self.chat_id}"

        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        data = json.loads(text_data)

        # Flutter sends basic fields — we enrich it
        raw_msg = data.get("msg")
        op = data.get("op", "new")

        # 👉 FIX: Create full message object that ChatUI expects
        message = {
            "id": raw_msg.get("id"),
            "authorId": raw_msg.get("authorId"),
            "text": raw_msg.get("text"),
            "createdAt": int(time() * 1000)  # milliseconds
        }

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "msg": message,
                "op": op,
            }
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            "op": event.get("op", "new"),
            "msg": event["msg"]
        }))
