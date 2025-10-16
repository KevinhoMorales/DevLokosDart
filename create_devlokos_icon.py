import os
from PIL import Image, ImageDraw, ImageFont

def create_devlokos_icon(output_path="assets/icons/app_icon.png", size=(1024, 1024)):
    """
    Crea el ícono oficial de DevLokos basado en el diseño proporcionado.
    """
    try:
        # Crear una imagen con fondo negro
        img = Image.new('RGBA', size, (0, 0, 0, 255))
        draw = ImageDraw.Draw(img)

        # Colores de marca
        orange = (255, 145, 77, 255) # #FF914D
        white = (255, 255, 255, 255)
        black = (0, 0, 0, 255)

        # Dimensiones relativas
        width, height = size
        center_x, center_y = width // 2, height // 2

        # === MICRÓFONO ===
        # Soporte del micrófono (rectángulo blanco vertical)
        stand_width = width // 12
        stand_height = height // 2.2
        stand_x = center_x - stand_width // 2
        stand_y = center_y - stand_height // 2 - height // 20
        
        draw.rounded_rectangle(
            (stand_x, stand_y, stand_x + stand_width, stand_y + stand_height),
            radius=stand_width // 3,
            fill=white
        )

        # Cabeza del micrófono (cápsula naranja)
        head_width = width // 4.5
        head_height = width // 7
        head_x = center_x - head_width // 2
        head_y = center_y + height // 15
        
        draw.rounded_rectangle(
            (head_x, head_y, head_x + head_width, head_y + head_height),
            radius=head_height // 2,
            fill=orange
        )

        # Líneas de la rejilla del micrófono (líneas negras)
        grille_lines = 5
        line_spacing = head_width // (grille_lines + 1)
        line_width = 2
        line_height = head_height // 3
        
        for i in range(grille_lines):
            line_x = head_x + line_spacing * (i + 1)
            line_y = head_y + (head_height - line_height) // 2
            draw.rectangle(
                (line_x - line_width // 2, line_y, line_x + line_width // 2, line_y + line_height),
                fill=black
            )

        # === TEXTO "DevLokos" ===
        # Intentar usar una fuente más grande y bold
        try:
            # Intentar cargar una fuente del sistema
            font_size = width // 8
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
            except:
                try:
                    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
                except:
                    font = ImageFont.load_default()
        except:
            font = ImageFont.load_default()

        # Texto "De" (blanco)
        de_text = "De"
        de_bbox = draw.textbbox((0, 0), de_text, font=font)
        de_width = de_bbox[2] - de_bbox[0]
        de_height = de_bbox[3] - de_bbox[1]
        de_x = center_x - width // 6
        de_y = center_y + height // 8
        
        draw.text((de_x, de_y), de_text, fill=white, font=font)

        # "V" estilizada naranja (más grande y prominente)
        v_text = "V"
        v_font_size = int(font_size * 1.8)  # V más grande
        try:
            v_font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", v_font_size)
        except:
            try:
                v_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", v_font_size)
            except:
                v_font = font
        
        v_bbox = draw.textbbox((0, 0), v_text, font=v_font)
        v_width = v_bbox[2] - v_bbox[0]
        v_height = v_bbox[3] - v_bbox[1]
        v_x = center_x - v_width // 2
        v_y = de_y - v_height // 4  # Posicionada ligeramente arriba
        
        draw.text((v_x, v_y), v_text, fill=orange, font=v_font)

        # Texto "okos" (blanco)
        okos_text = "okos"
        okos_x = center_x + width // 15
        okos_y = de_y
        
        draw.text((okos_x, okos_y), okos_text, fill=white, font=font)

        # Guardar la imagen
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        img.save(output_path, 'PNG')
        print(f"✅ Ícono DevLokos oficial creado exitosamente: {output_path}")
        print(f"   Dimensiones: {size[0]}x{size[1]} píxeles")
        print(f"   Colores: Naranja (#FF914D), Blanco, Negro")
        
    except Exception as e:
        print(f"❌ Error al crear el ícono: {e}")
        raise

if __name__ == "__main__":
    try:
        from PIL import Image, ImageDraw, ImageFont
        create_devlokos_icon()
    except ImportError:
        print("❌ PIL (Pillow) no está instalado. Instalando...")
        try:
            import subprocess
            subprocess.check_call(['pip', 'install', 'Pillow'])
            print("✅ Pillow instalado. Ejecuta el script nuevamente.")
        except Exception as e:
            print(f"❌ Error al instalar Pillow: {e}")
        exit()

