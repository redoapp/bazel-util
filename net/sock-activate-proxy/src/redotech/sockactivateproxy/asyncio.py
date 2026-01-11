async def pipe(reader, writer, buffer_size):
    try:
        while True:
            data = await reader.read(buffer_size)
            if not data:
                break
            writer.write(data)
    finally:
        writer.close()
