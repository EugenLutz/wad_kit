//
//  skeleton_interface.c
//  wad_kit
//
//  Created by Евгений Лютц on 06.06.20.
//  Copyright © 2020 Eugene Lutz. All rights reserved.
//

#include "skeleton_interface.h"
#include "skeleton.h"
#include "joint.h"
#include <stdlib.h>
#include <assert.h>


unsigned int skeletonGetNumJoints(SKELETON* skeleton)
{
	assert(skeleton);
	return skeleton->numJoints;
}

JOINT* skeletonGetJoint(SKELETON* skeleton, unsigned int jointIndex)
{
	assert(skeleton);
	assert(jointIndex < skeleton->numJoints);
	return &(skeleton->joints[jointIndex]);
}