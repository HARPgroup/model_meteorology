#include <iostream>
#include <fstream>
#include <cstdlib>
#include <sstream>

using namespace std;

int main(int argc, char** argv)
{
	string LandSegFolder, RNMaxFolder;
	int NumLandSegment;
	string LandSegment;
	double RNMax[12][31][24];

	LandSegFolder = argv[1];
	RNMaxFolder   = argv[2];
	NumLandSegment = atoi(argv[3]);

	char tFileName[2500];
	ifstream inputFileRAD;
	ofstream outputFileRNMax;
	string oneLine, strVal;
	int iYY, iMM, iDD, iHH;
	double tVal;


	//LandSegment = new string[NumLandSegment];
	for (int i=0; i<NumLandSegment; i++)
	{
		for (int mm = 0; mm < 12; mm++)
                	for (int dd = 0; dd < 31; dd++)
                        	for (int hh = 0; hh < 24; hh++)
                                	RNMax[mm][dd][hh] = -9.9;

		LandSegment = argv[4+i];
		cout << "\n" << LandSegment;

		sprintf(tFileName, "%s/%s.RAD", LandSegFolder.c_str(), LandSegment.c_str());
		inputFileRAD.open(tFileName, ios::in);
		if ( inputFileRAD.is_open() )
			cout << "\nFile opened: " << tFileName;
		else
		{
			cout << "\nUnable to open file: " << tFileName;
			return -1;
		}

		sprintf(tFileName, "%s/%s.RNMax", RNMaxFolder.c_str(), LandSegment.c_str());
		outputFileRNMax.open(tFileName, ios::out);
		if ( outputFileRNMax.is_open() )
                        cout << "\nFile opened: " << tFileName;
                else
                {
                        cout << "\nUnable to open file: " << tFileName;
                        return -1;
                }

		while ( std::getline( inputFileRAD, oneLine ) )
		{
			std::stringstream iStrStream (oneLine);
			getline(iStrStream, strVal, ','); iYY  = atoi(strVal.c_str());
			getline(iStrStream, strVal, ','); iMM  = atoi(strVal.c_str());
			getline(iStrStream, strVal, ','); iDD  = atoi(strVal.c_str());
			getline(iStrStream, strVal, ','); iHH  = atoi(strVal.c_str());
			getline(iStrStream, strVal, ','); tVal = atof(strVal.c_str());
			if ( RNMax[iMM-1][iDD-1][iHH-1] < tVal )
				RNMax[iMM-1][iDD-1][iHH-1] = tVal;
		}

		for (int mm = 0; mm < 12; mm++)
			for (int dd = 0; dd < 31; dd++)
				for (int hh = 0; hh < 24; hh++)
					outputFileRNMax << mm+1 << "," << dd+1 << "," << hh+1 << "," << RNMax[mm][dd][hh] << "\n";

		inputFileRAD.close();
		outputFileRNMax.close();
	}

	//delete [] LandSegment;



	cout << "\n\n";
}
