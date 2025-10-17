#!/usr/bin/env python3
import os
from PIL import Image

def generate_android_icons_from_devlokos():
    """
    Genera todos los tamaños de íconos necesarios para Android
    desde el ícono devlokos_icon.png existente.
    """
    # Tamaños requeridos para Android
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
            
            # Redimensionar el ícono
            resized_icon = base_icon.resize((size, size), Image.Resampling.LANCZOS)
            
            # Guardar como launcher_icon.png
            output_path = f"{output_dir}/launcher_icon.png"
            resized_icon.save(output_path, 'PNG')
            print(f"✅ Generado: {output_path} ({size}x{size})")
            
            # También guardar como ic_launcher.png
            ic_launcher_path = f"{output_dir}/ic_launcher.png"
            resized_icon.save(ic_launcher_path, 'PNG')
            print(f"✅ Generado: {ic_launcher_path} ({size}x{size})")
        
        print(f"\n🎉 Todos los íconos de Android generados desde devlokos_icon.png!")
        print("📱 Los íconos ahora usan el diseño DevLokos oficial")
        
    except Exception as e:
        print(f"❌ Error al generar íconos: {e}")
        raise

if __name__ == "__main__":
    try:
        from PIL import Image
        generate_android_icons_from_devlokos()
    except ImportError:
        print("❌ PIL (Pillow) no está instalado. Instalando...")
        try:
            import subprocess
            subprocess.check_call(['pip', 'install', 'Pillow'])
            print("✅ Pillow instalado. Ejecuta el script nuevamente.")
        except Exception as e:
            print(f"❌ Error al instalar Pillow: {e}")
        exit()
