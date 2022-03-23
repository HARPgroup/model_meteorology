#ifndef PICKGRIDVALUE
#define PICKGRIDVALUE

// ******************************************************************
// * Author: GOPAL BHATT (gopal.bhatt @ psu.edu)                    *
// ******************************************************************

#include <iostream>
#include <gdal.h>
#include <gdal_priv.h>

double readValue(void *data, GDALDataType type, int index);
void   getExtent(GDALDataset * temp, double *ranges);
double getRasterValue(GDALDataset * layer, int bandNumber, int x, int y);

#endif
