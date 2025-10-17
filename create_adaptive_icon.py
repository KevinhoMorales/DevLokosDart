#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

def create_adaptive_icon():
    """
    Crea un ícono adaptativo para Android usando devlokos_icon.png como base.
    Un ícono adaptativo tiene dos capas: foreground y background.
    """
    # Tamaños para íconos adaptativos
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    # Ruta del ícono base
    base_icon_path = "assets/icons/devlokos_icon.png"
    
    if not os.path.exists(base_icon_path):
        print(f"❌ Error: No se encontró el ícono base en {base_icon_path}")
        return
    
    try:
        # Cargar el ícono base
        base_icon = Image.open(base_icon_path)
        print(f"✅ Ícono base cargado: {base_icon.size}")
        
        # Generar cada tamaño
        for folder, size in sizes.items():
            # Crear directorio si no existe
            output_dir = f"android/app/src/main/res/{folder}"
            os.makedirs(output_dir, exist_ok=True)
            
            # Crear ícono adaptativo
            # El ícono adaptativo debe ser cuadrado y tener un área segura
            adaptive_size = size
            safe_area = int(adaptive_size * 0.66)  # 66% del área total es segura
            padding = (adaptive_size - safe_area) // 2
            
            # Crear fondo (background) - negro sólido
            background = Image.new('RGBA', (adaptive_size, adaptive_size), (0, 0, 0, 255))
            
            # Crear foreground - redimensionar el ícono original
            foreground_icon = base_icon.resize((safe_area, safe_area), Image.Resampling.LANCZOS)
            
            # Crear el foreground con transparencia
            foreground = Image.new('RGBA', (adaptive_size, adaptive_size), (0, 0, 0, 0))
            foreground.paste(foreground_icon, (padding, padding))
            
            # Guardar como launcher_icon.png (ícono tradicional)
            output_path = f"{output_dir}/launcher_icon.png"
            foreground.save(output_path, 'PNG')
            print(f"✅ Generado: {output_path} ({adaptive_size}x{adaptive_size})")
            
            # Guardar como ic_launcher.png
            ic_launcher_path = f"{output_dir}/ic_launcher.png"
            foreground.save(ic_launcher_path, 'PNG')
            print(f"✅ Generado: {ic_launcher_path} ({adaptive_size}x{adaptive_size})")
            
            # Crear íconos adaptativos
            # Background
            background_path = f"{output_dir}/ic_launcher_background.png"
            background.save(background_path, 'PNG')
            print(f"✅ Generado: {background_path} ({adaptive_size}x{adaptive_size})")
            
            # Foreground (con máscara circular)
            foreground_mask = Image.new('L', (adaptive_size, adaptive_size), 0)
            draw = ImageDraw.Draw(foreground_mask)
            draw.ellipse([0, 0, adaptive_size, adaptive_size], fill=255)
            
            # Aplicar máscara al foreground
            foreground_masked = Image.new('RGBA', (adaptive_size, adaptive_size), (0, 0, 0, 0))
            foreground_masked.paste(foreground_icon, (padding, padding))
            foreground_masked.putalpha(foreground_mask)
            
            foreground_path = f"{output_dir}/ic_launcher_foreground.png"
            foreground_masked.save(foreground_path, 'PNG')
            print(f"✅ Generado: {foreground_path} ({adaptive_size}x{adaptive_size})")
        
        print(f"\n🎉 Todos los íconos adaptativos generados exitosamente!")
        print("📱 Los íconos ahora se verán bien en todos los launchers de Android")
        
    except Exception as e:
        print(f"❌ Error al generar íconos adaptativos: {e}")
        raise

if __name__ == "__main__":
    try:
        from PIL import Image, ImageDraw
        create_adaptive_icon()
    except ImportError:
        print("❌ PIL (Pillow) no está instalado. Instalando...")
        try:
            import subprocess
            subprocess.check_call(['pip', 'install', 'Pillow'])
            print("✅ Pillow instalado. Ejecuta el script nuevamente.")
        except Exception as e:
            print(f"❌ Error al instalar Pillow: {e}")
        exit()
