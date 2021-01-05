//
//  graphics_drawable_interface.h
//  wad_editor_lib
//
//  Created by Евгений Лютц on 05.01.21.
//  Copyright © 2021 Eugene Lutz. All rights reserved.
//

#ifndef graphics_drawable_interface_h
#define graphics_drawable_interface_h

#include "wad_editor_lib.h"

void graphicsDrawableReturn(GRAPHICS_DRAWABLE* graphicsDrawable);

TEXTURE2D* graphicsDrawableGetTexture(GRAPHICS_DRAWABLE* graphicsDrawable);

#endif /* graphics_drawable_interface_h */
