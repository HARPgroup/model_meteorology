#include <iostream>
#include <fstream>
#include <iomanip>
#include <ctime>
#include <string>
#include <stdlib.h>
#include <cmath>

using namespace std;

#define DEBUG0 if(1)
#define DEBUG1 if(0)
#define DEBUG2 if(0)


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
        return;
}


int main(int argc, char* argv[])
{
	string LSEG_NLDAS_MAP;
	string ASCII_FOLDER;
	string LSEG_FOLDER;

	struct tm sLocalTime, *sGMTUTC;
        struct tm eLocalTime, *eGMTUTC;
	struct tm tLocalTime;
	time_t sTimeT, eTimeT;

	ASCII_FOLDER = argv[1];
	LSEG_FOLDER  = argv[2];

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

	LSEG_NLDAS_MAP = argv[11];

	eTimeT = mktime(&eLocalTime);
	sTimeT = mktime(&sLocalTime);
	DEBUG0 cout << "\nStart: " << asctime(&sLocalTime);
	DEBUG0 cout << "\nStop : " << asctime(&eLocalTime);

	int NumSeconds = (int) difftime(eTimeT, sTimeT) + 1*60*60;
        int NumHours   = NumSeconds / 3600;

	char tFileName[2500];

	ifstream LandSegNLDASFile;
        //LandSegNLDASFile.open("land-seg-nldas.txt");
        sprintf(tFileName,"%s", LSEG_NLDAS_MAP.c_str());
        LandSegNLDASFile.open(tFileName, ios::in);
        int NumLandSeg; LandSegNLDASFile >> NumLandSeg;

	string LandSeg;
	string NLDAS[100];
	int NumNLDAS;
	int YEAR;
	ifstream *ETFile, *PPFile, *RHFile, *RNFile, *TTFile, *VPFile, *WDFile;
	ofstream *DPTFile, *PETFile, *PRCFile, *RADFile, *TMPFile, *WNDFile;
	double DPT, PET, PRC, RAD, RHX, TMP, WND, tVal;
	int tYear, tMonth, tDay, tHour;
	int posET, posPP, posRH, posRN, posTT, posVP, posWD;

	DPTFile = new ofstream[NumLandSeg];
	PETFile = new ofstream[NumLandSeg];
	PRCFile = new ofstream[NumLandSeg];
	RADFile = new ofstream[NumLandSeg];
	TMPFile = new ofstream[NumLandSeg];
	WNDFile = new ofstream[NumLandSeg];

	for (int i=0; i<NumLandSeg; i++)
	{
		LandSegNLDASFile >> LandSeg;
		sprintf( tFileName, "%s/%4d%02d%02d%02d-%4d%02d%02d%02d/%s.DPT", LSEG_FOLDER.c_str(), 1900+sLocalTime.tm_year, sLocalTime.tm_mon+1, sLocalTime.tm_mday, sLocalTime.tm_hour, 1900+eLocalTime.tm_year, eLocalTime.tm_mon+1, eLocalTime.tm_mday, eLocalTime.tm_hour, LandSeg.c_str() );
		DPTFile[i].open( tFileName, ios::out );
		if ( DPTFile[i].is_open() )
			cout << "\nFile Opened: " << tFileName;
		else
			{ cout << "\nError Opening File: " << tFileName << "\n"; return -1; }
		sprintf( tFileName, "%s/%4d%02d%02d%02d-%4d%02d%02d%02d/%s.PET", LSEG_FOLDER.c_str(), 1900+sLocalTime.tm_year, sLocalTime.tm_mon+1, sLocalTime.tm_mday, sLocalTime.tm_hour, 1900+eLocalTime.tm_year, eLocalTime.tm_mon+1, eLocalTime.tm_mday, eLocalTime.tm_hour, LandSeg.c_str() );
		PETFile[i].open( tFileName, ios::out );
                if ( PETFile[i].is_open() )
                        cout << "\nFile Opened: " << tFileName;
                else
                        { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }
		sprintf( tFileName, "%s/%4d%02d%02d%02d-%4d%02d%02d%02d/%s.PRC", LSEG_FOLDER.c_str(), 1900+sLocalTime.tm_year, sLocalTime.tm_mon+1, sLocalTime.tm_mday, sLocalTime.tm_hour, 1900+eLocalTime.tm_year, eLocalTime.tm_mon+1, eLocalTime.tm_mday, eLocalTime.tm_hour, LandSeg.c_str() );
		PRCFile[i].open( tFileName, ios::out );
                if ( PRCFile[i].is_open() )
                        cout << "\nFile Opened: " << tFileName;
                else
                        { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }
		sprintf( tFileName, "%s/%4d%02d%02d%02d-%4d%02d%02d%02d/%s.RAD", LSEG_FOLDER.c_str(), 1900+sLocalTime.tm_year, sLocalTime.tm_mon+1, sLocalTime.tm_mday, sLocalTime.tm_hour, 1900+eLocalTime.tm_year, eLocalTime.tm_mon+1, eLocalTime.tm_mday, eLocalTime.tm_hour, LandSeg.c_str() );
		RADFile[i].open( tFileName, ios::out );
                if ( RADFile[i].is_open() )
                        cout << "\nFile Opened: " << tFileName;
                else
                        { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }
		sprintf( tFileName, "%s/%4d%02d%02d%02d-%4d%02d%02d%02d/%s.TMP", LSEG_FOLDER.c_str(), 1900+sLocalTime.tm_year, sLocalTime.tm_mon+1, sLocalTime.tm_mday, sLocalTime.tm_hour, 1900+eLocalTime.tm_year, eLocalTime.tm_mon+1, eLocalTime.tm_mday, eLocalTime.tm_hour, LandSeg.c_str() );
		TMPFile[i].open( tFileName, ios::out );
                if ( TMPFile[i].is_open() )
                        cout << "\nFile Opened: " << tFileName;
                else
                        { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }
		sprintf( tFileName, "%s/%4d%02d%02d%02d-%4d%02d%02d%02d/%s.WND", LSEG_FOLDER.c_str(), 1900+sLocalTime.tm_year, sLocalTime.tm_mon+1, sLocalTime.tm_mday, sLocalTime.tm_hour, 1900+eLocalTime.tm_year, eLocalTime.tm_mon+1, eLocalTime.tm_mday, eLocalTime.tm_hour, LandSeg.c_str() );
		WNDFile[i].open( tFileName, ios::out );
                if ( WNDFile[i].is_open() )
                        cout << "\nFile Opened: " << tFileName;
                else
                        { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

		LandSegNLDASFile >> NumNLDAS;

		DEBUG0 cout << "\n" << LandSeg << " " << NumNLDAS << " ";
		for (int j=0; j<NumNLDAS; j++)
		{
			LandSegNLDASFile >> NLDAS[j];
			DEBUG0 cout <<  NLDAS[j] << " ";
		}

		tLocalTime.tm_year = sLocalTime.tm_year;
                tLocalTime.tm_mon  = sLocalTime.tm_mon;
                tLocalTime.tm_mday = sLocalTime.tm_mday;
                tLocalTime.tm_hour = sLocalTime.tm_hour;
                tLocalTime.tm_min  = 0;
                tLocalTime.tm_sec  = 0;
                tLocalTime.tm_isdst= 0;
		mktime(&tLocalTime);
		YEAR = 9999;

		cout << "\n" << LandSeg << " " << asctime(&tLocalTime) << "\n";

		ETFile = new ifstream[NumNLDAS];
		PPFile = new ifstream[NumNLDAS];
		RHFile = new ifstream[NumNLDAS];
		RNFile = new ifstream[NumNLDAS];
		TTFile = new ifstream[NumNLDAS];
		VPFile = new ifstream[NumNLDAS];
		WDFile = new ifstream[NumNLDAS];

		for (int j=0; j<NumHours; j++ )
		{
			DPT = PET = PRC = RAD = RHX = TMP = WND = 0.0;
			if(YEAR != tLocalTime.tm_year)
			{
				for (int k=0; k<NumNLDAS; k++)
                        	{
					YEAR = tLocalTime.tm_year;

					if ( ETFile[k].is_open() ) ETFile[k].close();
					if ( PPFile[k].is_open() ) PPFile[k].close();
					if ( RHFile[k].is_open() ) RHFile[k].close();
					if ( RNFile[k].is_open() ) RNFile[k].close();
					if ( TTFile[k].is_open() ) TTFile[k].close();
					if ( VPFile[k].is_open() ) VPFile[k].close();
					if ( WDFile[k].is_open() ) WDFile[k].close();

					sprintf( tFileName, "%s/%d/%szET.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
					ETFile[k].open( tFileName, ios::in );
					if ( ETFile[k].is_open() )
						cout << "\nFile Opened: " << tFileName;
					else
						{ cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					sprintf( tFileName, "%s/%d/%szPP.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
                                        PPFile[k].open( tFileName, ios::in );
                                        if ( PPFile[k].is_open() ) 
                                                cout << "\nFile Opened: " << tFileName;
                                        else
                                                { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					sprintf( tFileName, "%s/%d/%szRH.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
                                        RHFile[k].open( tFileName, ios::in );
                                        if ( RHFile[k].is_open() ) 
                                                cout << "\nFile Opened: " << tFileName;
                                        else
                                                { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					sprintf( tFileName, "%s/%d/%szRN.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
                                        RNFile[k].open( tFileName, ios::in );
                                        if ( RNFile[k].is_open() ) 
                                                cout << "\nFile Opened: " << tFileName;
                                        else
                                                { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					sprintf( tFileName, "%s/%d/%szVP.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
                                        VPFile[k].open( tFileName, ios::in );
                                        if ( VPFile[k].is_open() )
                                                cout << "\nFile Opened: " << tFileName;
                                        else
                                                { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					sprintf( tFileName, "%s/%d/%szTT.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
                                        TTFile[k].open( tFileName, ios::in );
                                        if ( TTFile[k].is_open() ) 
                                                cout << "\nFile Opened: " << tFileName;
                                        else
                                                { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					sprintf( tFileName, "%s/%d/%szWD.txt", ASCII_FOLDER.c_str(), 1900+YEAR, NLDAS[k].c_str() );
                                        WDFile[k].open( tFileName, ios::in );
                                        if ( WDFile[k].is_open() ) 
                                                cout << "\nFile Opened: " << tFileName;
                                        else
                                                { cout << "\nError Opening File: " << tFileName << "\n"; return -1; }

					tMonth = -9999;
					if ( j == 0 )
					{
						//SKIP OVER LINES TO REACH START TIME
						while ( !(tMonth == tLocalTime.tm_mon+1 && tDay == tLocalTime.tm_mday && tHour == tLocalTime.tm_hour+1) )
						{
							posET = ETFile[k].tellg();
							ETFile[k] >> tYear; ETFile[k] >> tMonth; ETFile[k] >> tDay; ETFile[k] >> tHour; ETFile[k] >> tVal;

							posRH = RHFile[k].tellg();
                                                        RNFile[k] >> tYear; RHFile[k] >> tMonth; RHFile[k] >> tDay; RHFile[k] >> tHour; RHFile[k] >> tVal;

							posRN = RNFile[k].tellg();
                                                        RNFile[k] >> tYear; RNFile[k] >> tMonth; RNFile[k] >> tDay; RNFile[k] >> tHour; RNFile[k] >> tVal;

							posTT = TTFile[k].tellg();
                                                        TTFile[k] >> tYear; TTFile[k] >> tMonth; TTFile[k] >> tDay; TTFile[k] >> tHour; TTFile[k] >> tVal;

							posVP = VPFile[k].tellg();
                                                        VPFile[k] >> tYear; VPFile[k] >> tMonth; VPFile[k] >> tDay; VPFile[k] >> tHour; VPFile[k] >> tVal;

							posWD = WDFile[k].tellg();
                                                        WDFile[k] >> tYear; WDFile[k] >> tMonth; WDFile[k] >> tDay; WDFile[k] >> tHour; WDFile[k] >> tVal;

							cout << "\n$ " << tYear << " " << tMonth << " " << tDay << " " << tHour << "\n";
							cout << "% " << 1900+tLocalTime.tm_year << " " << tLocalTime.tm_mon+1 << " " << tLocalTime.tm_mday << " " << tLocalTime.tm_hour+1 << "\n";
						}
						ETFile[k].seekg(posET);
						RHFile[k].seekg(posRH);
						RNFile[k].seekg(posRN);
						TTFile[k].seekg(posTT);
						VPFile[k].seekg(posVP);
						WDFile[k].seekg(posWD);
					}
			
				}
			}
			for (int k=0; k<NumNLDAS; k++)
                        {
				//posPP, posRH, posRN, posTT, posVP, posWD
				ETFile[k] >> tYear; ETFile[k] >> tMonth; ETFile[k] >> tDay; ETFile[k] >> tHour;
				ETFile[k] >> tVal; PET += tVal/NumNLDAS;

				PPFile[k] >> tYear; PPFile[k] >> tMonth; PPFile[k] >> tDay; PPFile[k] >> tHour;
                                PPFile[k] >> tVal; PRC += tVal/NumNLDAS;

				RHFile[k] >> tYear; RHFile[k] >> tMonth; RHFile[k] >> tDay; RHFile[k] >> tHour;
				RHFile[k] >> tVal; tVal = tVal > 1 ? 1 : ( tVal <= 0 ? 0.01 : tVal); RHX += tVal/NumNLDAS;

				RNFile[k] >> tYear; RNFile[k] >> tMonth; RNFile[k] >> tDay; RNFile[k] >> tHour;
                                RNFile[k] >> tVal; RAD += tVal/NumNLDAS;

				TTFile[k] >> tYear; TTFile[k] >> tMonth; TTFile[k] >> tDay; TTFile[k] >> tHour;
				TTFile[k] >> tVal; TMP += tVal/NumNLDAS;

				WDFile[k] >> tYear; WDFile[k] >> tMonth; WDFile[k] >> tDay; WDFile[k] >> tHour;
				WDFile[k] >> tVal; WND += tVal/NumNLDAS;
			}
			//cout << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << "\n";
			DPT = 237.7 * ( (17.271*TMP/(237.7+TMP)) + log(RHX) ) / (17.271 - ( (17.271*TMP/(237.7+TMP)) + log(RHX) ));
			DPTFile[i] << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << DPT << "\n";
			PETFile[i] << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << PET << "\n";
			PRCFile[i] << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << PRC << "\n";
			RADFile[i] << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << RAD << "\n";
			TMPFile[i] << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << TMP << "\n";
			WNDFile[i] << tYear << "," << tMonth << "," << tDay << "," << tHour << "," << WND << "\n";
			clockOneHour(&tLocalTime);
		}

		DPTFile[i].close();
		PETFile[i].close();
		PRCFile[i].close();
		RADFile[i].close();
		TMPFile[i].close();
		WNDFile[i].close();
		delete [] ETFile;
	}


	delete [] DPTFile;
	delete [] PETFile;
	delete [] PRCFile;
	delete [] RADFile;
	delete [] TMPFile;
	delete [] WNDFile;



	cout << "\n\n";
}
