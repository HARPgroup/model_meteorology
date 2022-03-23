// ******************************************************************
// * EXTRACT NLDAS-2 CLIMATE DATA                                   *
// * Version 2.0                                                    *
// * Author: GOPAL BHATT (gopal.bhatt @ psu.edu)                    *
// ET – Potential Evapotranspiration (inches/hour)
// PP – Precipitation (inches/hour)
// RH – Relative Humidity (fraction)
// RN – Solar Radiation (lagley/hour)
// TT – Air Temperature at 10 meters (degree C)
// VP – Vapor Pressure in (Pascals)
// WD – Wind Speed (miles/hours)
// ******************************************************************

#include <iostream>
#include <fstream>
#include <iomanip>
#include <ctime>
#include <string>

#include "pickGridVal.h"

using namespace std;

#define DEBUG0 if(1)
#define DEBUG1 if(1)
#define DEBUG2 if(0)

typedef struct {
        int row;
        int col;
} GRIDS;

void backOneHour(struct tm * t)
{
        t->tm_hour -= 1;
        mktime(t);
        DEBUG1 cout << "Time: " << asctime(t);
        return;
}

void clockOneHour(struct tm * t)
{
	DEBUG1 cout << "Time: " << asctime(t);
	t->tm_hour += 1;
	mktime(t);
	//DEBUG1 cout <<"\nTime " << t->tm_year + 1900 << " " << t->tm_mon + 1 << " " << t->tm_mday << " " << t->tm_hour;
	//DEBUG1 cout << "Time: " << asctime(t);
	return;
}


int main(int argc, char* argv[])
{
        //char NLDAS_FOLDER[1000];
	const char *NLDAS_FOLDER = NULL;
        char OUT_FOLDER[1000];

	//struct tm 1900 0-11 1-31 0-23
	struct tm sLocalTime, *sGMTUTC;
        struct tm eLocalTime, *eGMTUTC;
        time_t sTimeT, eTimeT;

	int   NumGrid;
	GRIDS *grid;

        //sprintf(NLDAS_FOLDER, "%s", argv[1]);
        //strcpy(NLDAS_FOLDER, argv[1]);
        NLDAS_FOLDER = argv[1];
        sprintf(OUT_FOLDER,   "%s", argv[2]);

        tzset();
	//tzname[0]= "EST";
	//tzname[1]= "EDT";
	setenv("TZ", "EST5EDT",1);
	tzset();
	cout << "BHATT" << tzname[0] << "\t" << tzname[1] << "\n";
	if ( argc >= 14 )
	{
		sLocalTime.tm_year = atoi(argv[3])-1900;
        	sLocalTime.tm_mon  = atoi(argv[4])-1;
	        sLocalTime.tm_mday = atoi(argv[5]);
        	sLocalTime.tm_hour = atoi(argv[6]);
		sLocalTime.tm_min  = 0;
		sLocalTime.tm_sec  = 0;
		sLocalTime.tm_isdst= 0;


	        eLocalTime.tm_year = atoi(argv[7])-1900;
        	eLocalTime.tm_mon  = atoi(argv[8])-1;
	        eLocalTime.tm_mday = atoi(argv[9]);
		eLocalTime.tm_hour = atoi(argv[10]);
		eLocalTime.tm_min  = 0;
		eLocalTime.tm_sec  = 0;
		eLocalTime.tm_isdst= 0;

		NumGrid = atoi(argv[11]);

		grid = (GRIDS *) malloc(NumGrid * sizeof(GRIDS));
		for (int i = 0; i < NumGrid; i++)
		{
                	grid[i].col = atoi(argv[12+2*i]);
                	grid[i].row = atoi(argv[13+2*i]);
			cout << i+1 << " " << grid[i].col << " " << grid[i].row << "\n";
        	}
	}
	else if (argc == 8)
	{
	        sLocalTime.tm_year = atoi(argv[3])-1900;
                sLocalTime.tm_mon  = 1-1;
                sLocalTime.tm_mday = 1;
                sLocalTime.tm_hour = 1;
                sLocalTime.tm_min  = 0;
                sLocalTime.tm_sec  = 0;
		sLocalTime.tm_isdst= -1;

                eLocalTime.tm_year = atoi(argv[4])-1900;
                eLocalTime.tm_mon  = 12-1;
                eLocalTime.tm_mday = 31;
                eLocalTime.tm_hour = 23;
                eLocalTime.tm_min  = 0;
                eLocalTime.tm_sec  = 0;
		eLocalTime.tm_isdst= -1;

                NumGrid = atoi(argv[5]);

                grid = (GRIDS *) malloc(NumGrid * sizeof(GRIDS));
                for (int i = 0; i < NumGrid; i++)
		{
                        grid[i].col = atoi(argv[6+2*i]);
                        grid[i].row = atoi(argv[7+2*i]);
			cout << i+1 << " " << grid[i].col << " " << grid[i].row << "\n";
                }
	}
	else
	{
		cout << "\nMissing inputs. Exiting... \n";
		return 0;
	}

	DEBUG0 cout << "\nNLDAS Folder = " << NLDAS_FOLDER;
        DEBUG0 cout << "\nOut   Folder = " << OUT_FOLDER;
        DEBUG0 cout << "\nNum of Grids = " << NumGrid;


	eTimeT = mktime(&eLocalTime);
	eGMTUTC = gmtime ( &eTimeT );
        //cout <<"\nInput Local Time  : " << eLocalTime.tm_year + 1900 << " " << eLocalTime.tm_mon + 1 << " " << eLocalTime.tm_mday << " " << eLocalTime.tm_hour;
        //cout <<"\nAdjusted GMT/UTC  : " << eGMTUTC->tm_year + 1900 << " " << eGMTUTC->tm_mon + 1 << " " << eGMTUTC->tm_mday << " " << eGMTUTC->tm_hour;
        cout <<"\nStop Local Time  : " << asctime(&eLocalTime);
	cout <<"Adjusted Stop GMT/UTC   : " << asctime(eGMTUTC);

	sTimeT = mktime(&sLocalTime);
        sGMTUTC = gmtime ( &sTimeT );
        //cout <<"\nInpt Local Time  : " << sLocalTime.tm_year + 1900 << " " << sLocalTime.tm_mon + 1 << " " << sLocalTime.tm_mday << " " << sLocalTime.tm_hour;
        //cout <<"\nAdjusted GMT/UTC  : " << sGMTUTC->tm_year + 1900 << " " << sGMTUTC->tm_mon + 1 << " " << sGMTUTC->tm_mday << " " << sGMTUTC->tm_hour;

        cout <<"\nStart Local Time   : " << asctime(&sLocalTime);
        cout <<"Adjusted Start GMT/UTC   : " << asctime(sGMTUTC);

	int NumSeconds = (int) difftime(eTimeT, sTimeT) + 1*60*60;
        int NumHours   = NumSeconds / 3600;
        cout << "\nNumSeconds = " << NumSeconds << " NumHours = " << NumHours << "\n";

	double *Tavg = new double[NumGrid];
        double *TotRn = new double[NumGrid];
        int *DayLightHours = new int [NumGrid];
        double **Rn = new double*[NumGrid];
	for (int i=0; i<NumGrid; i++)
		Rn[i] = new double[24];
	double VDsat, PET;
	
	char     row[10], col[10], filename[2500];
	int NumYears = eLocalTime.tm_year - sLocalTime.tm_year + 1;
	ofstream ***files = new ofstream **[NumYears];
	for (int i = 0; i < NumYears; i++)
	{
        	files[i] = new ofstream *[NumGrid];
	        for (int j = 0; j < NumGrid; j++)
        	        files[i][j] = new ofstream[8];
	}

	char OUT_FOLDER_YR[1005];	
	for (int j = 0; j < NumYears; j++)
	{
		sprintf(OUT_FOLDER_YR,"%s/%d",OUT_FOLDER,1900+sLocalTime.tm_year+j);
		//mkdir( OUT_FOLDER_YR, S_IRWXU);
		mkdir( OUT_FOLDER_YR, S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
		for (int i = 0; i < NumGrid; i++)
		{
	       	        //sprintf(row, "%d", grid[i].row);
	                //sprintf(col, "%d", grid[i].col);
	                sprintf(filename, "%s/x%dy%dzPP.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
	                DEBUG0 cout << "\ne.g. output filename " << filename << " " << i << " " << j;
	                files[j][i][0].open(filename, ios::out);
			//if ( files[j][i][0].is_open() ) cout << " File open for writing " << filename << "\n";
			//else { cout << "Unable to open file " << filename << "\n"; return 0; }
	                files[j][i][0] << fixed;

	                sprintf(filename, "%s/x%dy%dzTT.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
	                files[j][i][1].open(filename, ios::out);
	                files[j][i][1] << fixed;

	                sprintf(filename, "%s/x%dy%dzRH.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
	                files[j][i][2].open(filename, ios::out);
	                files[j][i][2] << fixed;

	                sprintf(filename, "%s/x%dy%dzWD.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
	                files[j][i][3].open(filename, ios::out);
	                files[j][i][3] << fixed;

	                sprintf(filename, "%s/x%dy%dzRN.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
	                files[j][i][4].open(filename, ios::out);
	                files[j][i][4] << fixed;

	                sprintf(filename, "%s/x%dy%dzVP.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
	                files[j][i][5].open(filename, ios::out);
	                files[j][i][5] << fixed;

			sprintf(filename, "%s/x%dy%dzET.txt", OUT_FOLDER_YR, grid[i].col, grid[i].row);
                        files[j][i][6].open(filename, ios::out);
                        files[j][i][6] << fixed;
		}
        }

	double          gridValue[7], V, VP, VPsat;
        GDALDataset    *hourGDAL;
        GDALAllRegister();

	char grbFileName[400], fileA[20], fileB[20], stry[5],
             strm[3], str3d[4], str2d[3], strh[5];
        int  yyyy, mm, dd, dd2, hh;

        double est = ((23.0 / (2 * 60)) / 8760) * NumGrid * NumHours;
        cout << "Estimated Run Time: ~" << est << " Hrs. \n";
        if (est > 1.0)
                cout << "\nTime for some coffee?\n";
        else if (est > 24.0)
                cout << "\nTry breaking the jobs into pices!!\n";
        else if (est > 24.0 * 7)
                cout << "\nMore than a week? seriously?\nConsider breaking the input into smaller groups\n";

        ifstream        grbFile;

	int StartYr = sLocalTime.tm_year;
	//backOneHour(&sLocalTime); // LAG ONE HOUR FOR PRINTING AS HSPF WOULD NEED DATA FOR COMING ONE HOUR
	clockOneHour(sGMTUTC);
	DEBUG2 cout << "YRS: " << StartYr  << " " << sLocalTime.tm_year;
	for (int i = 0; i < NumHours; i++)
	{

                sprintf(grbFileName, "%s/%04d/%03d/NLDAS_FORA0125_H.A%04d%02d%02d.%04d.002.grb", NLDAS_FOLDER, sGMTUTC->tm_year+1900, sGMTUTC->tm_yday+1, sGMTUTC->tm_year+1900, sGMTUTC->tm_mon+1, sGMTUTC->tm_mday, 100*sGMTUTC->tm_hour);
                DEBUG0 cout << "GRIB File: " << grbFileName << "\n";


                hourGDAL = (GDALDataset *) GDALOpen(grbFileName, GA_ReadOnly);

		for (int j = 0; j < NumGrid; j++) {
                        //DEBUG0 cout << "$#" << getRasterValue(hourGDAL, 10, grid[j].row, grid[j].col) << "\n";
                        gridValue[0] = getRasterValue(hourGDAL, 10, 224 - grid[j].row, grid[j].col - 1);
			gridValue[1] = getRasterValue(hourGDAL, 1, 224 - grid[j].row, grid[j].col - 1);
			gridValue[2] = getRasterValue(hourGDAL, 2, 224 - grid[j].row, grid[j].col - 1);
			gridValue[3] = getRasterValue(hourGDAL, 4, 224 - grid[j].row, grid[j].col - 1);
			gridValue[4] = getRasterValue(hourGDAL, 11, 224 - grid[j].row, grid[j].col - 1);
			gridValue[5] = getRasterValue(hourGDAL, 5, 224 - grid[j].row, grid[j].col - 1);
			gridValue[6] = getRasterValue(hourGDAL, 3, 224 - grid[j].row, grid[j].col - 1);

			VP = gridValue[6] * (gridValue[2] / (gridValue[2] + 0.62198));
                        VPsat = 611.2 * exp(17.62 * gridValue[1] / (243.12 + gridValue[1]));
                        V = sqrt(gridValue[3] * gridValue[3] + gridValue[5] * gridValue[5]);

			DEBUG2 cout << "YRS: " << StartYr  << " " << sLocalTime.tm_year; //getchar(); getchar();
			files[StartYr-sLocalTime.tm_year][j][0] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t"  << sLocalTime.tm_hour+1 << "\t" << setprecision(6)  << gridValue[0] * 0.0393713 << "\n"; // [1 kg/m2/hr] [1/999.97 m3/kg] [ 39.3701 inces/m ]

			files[StartYr-sLocalTime.tm_year][j][1] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t" << sLocalTime.tm_hour+1 << "\t" << setprecision(2) << gridValue[1] << "\n";

			files[StartYr-sLocalTime.tm_year][j][2] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t" << sLocalTime.tm_hour+1 << "\t" << setprecision(4) << VP / VPsat  << "\n";

			files[StartYr-sLocalTime.tm_year][j][3] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t" << sLocalTime.tm_hour+1 << "\t" << setprecision(2) << V * 2.23694 << "\n"; // [ 1 m/s ] = [ 2.23694 mph ]

			files[StartYr-sLocalTime.tm_year][j][4] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t" << sLocalTime.tm_hour+1 << "\t" << setprecision(2) << 0.08604206501 * gridValue[4]  << "\n"; // [1 J/m2/s] [ 60*60 s/hr ] [ 1/41840 lagley / (J/m2) ]

			files[StartYr-sLocalTime.tm_year][j][5] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t" << sLocalTime.tm_hour+1 << "\t" << setprecision(4) << VP << "\n";

			if ( sLocalTime.tm_hour+1 == 1 )
			{
				Tavg[j]  = 0;
				TotRn[j] = 0;
				DayLightHours[j] = 0;
			}
			Tavg[j] += gridValue[1] / 24;
			Rn[j][sLocalTime.tm_hour] = gridValue[4];
			TotRn[j] += gridValue[4];
			if ( gridValue[4] > 0 )
				DayLightHours[j]++;
			if ( sLocalTime.tm_hour+1 == 24 )
			{
				VPsat = 6.108 * exp(17.26939 * Tavg[j] / (Tavg[j] + 237.3));
				VDsat = 216.7 * VPsat / (Tavg[j] + 273.3);
				PET   = 0.0055 * pow(DayLightHours[j] / 12.0, 2) * VDsat; //Inches per Day
				for(int k = 0; k < 24; k++)
				{
					files[StartYr-sLocalTime.tm_year][j][6] << sLocalTime.tm_year+1900 << "\t" << sLocalTime.tm_mon+1 << "\t" << sLocalTime.tm_mday << "\t" << k+1 << "\t" << setprecision(6) << (Rn[j][k] / TotRn[j]) * PET << "\n";
				}
			}
			
		}

		GDALClose(hourGDAL);

                clockOneHour(sGMTUTC);
		clockOneHour(&sLocalTime);
	}

	for (int k = 0; k < NumYears; k++)
	for (int i = 0; i < NumGrid; i++) {
                for (int j = 0; j < 7; j++) {
                        files[k][i][j].flush();
                        files[k][i][j].close();
                }
        }





	cout << "\n\n";
}
