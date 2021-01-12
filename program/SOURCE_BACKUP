#include <iostream>
#include <string>
#include <fstream>
#include <algorithm>
#include <vector>
using namespace std;

#define USAGE "Usage: seadidx <file input>"

/** 
	Retorna el tamaño de la cadena real, los acentos computan como
	si fueran dos carácteres porque se almacenan en 2 bytes.
**/
unsigned int strSize(string &str)
{
	unsigned int size=str.length();
	
	
	for (unsigned int i=0; i<str.length(); ++i)
	{
		if (int(str[i])<0) 
			--size;
			++i;
	}

	return size;
}

/** 
	Cuenta la cantidad de dígitos que tiene el número de línea donde se
	encuentra cada sección para poder dar el formato deseado de forma
	que sabiendo la cantidad de carácteres hay, se puede saber cuantos
	puntos harían falta para lograr el efecto rectangular.
**/
unsigned int numDigits(unsigned int number)
{
    int digits = 0;
    if (number < 0) digits = 1; // remove this line if '-' counts as a digit
    while (number) {
        number /= 10;
        digits++;
    }
    return digits;
}

/** 
	Formatea el índice obtenido para que sea visiblemente estético y se vea
	con una forma rectangular.
**/
string format (vector<pair<string, unsigned int> > &str, unsigned int max)
{
	max+=max/4;
	
	string formated = "# INDEX\n-------\n\n";
	
	for (unsigned int i=0; i<str.size(); ++i) {
		formated += str[i].first;

		int len=str[i].second+str.size()+5;
		int dots=strSize(str[i].first)+numDigits(len);
		
		for (unsigned int j=0; j<(max-dots); ++j) formated+= ".";
		formated += "" + to_string(len) + "\n";
	}
	return formated;
}

/** 
	Lee el fichero dado por parámetro dos vueltas, la primera se encarga de recoger
	la información. En la segunda de escribir replicando los datos conforme va iterando 
	además de incluir el índice en la segunda línea.
	La entrada del informe debe ser nombre_no-idx.txt.
	La salida es nombre_idx.txt
**/
int main(int argc, char** argv)
{
	if (argc < 2) {
		cout << USAGE << endl;
		exit(-1);
	}
	
	string file = argv[1];
	
	string buffer;
	string tmp;
	vector<pair<string, unsigned int> > index;
	unsigned int nline=0;
	unsigned int max=0;
	bool section = false;
	
	bool write = false;
	bool oneTime = false;
	
	ifstream myReadFile;
	ofstream myWriteFile;
	
	while (not write or not oneTime)
	{
		
		if (oneTime) write = true;
		
		myReadFile.open(file);
		
		if (write) myWriteFile.open(file.substr(0,file.find("no-idx"))+"idx.txt");

		 
		if (myReadFile.is_open()) {
			if (write and not myWriteFile.is_open())
			{
				cout << "Nothing to write" << endl;
				exit(-1);
			}
			string line;
			while (getline(myReadFile, line)) {
				
				if (not write)
				{
				
					if (section)
						if (line.substr(0,3) == "---") {
							section = false;
							index.push_back(make_pair("(*) " + tmp, nline));
						}
					
					
					if (line[0] == '#') {
						section = true;
						tmp = line.substr (2,line.length());
						if (tmp.length()+4>max) max=line.length()+4;
					}
				}else{
					myWriteFile << line << endl;
					if (nline == 2) myWriteFile << format(index, max) << endl << endl;
				}					
				
				++nline;
			}
			myReadFile.close();
			nline = 0;
			
		}else{
			cout << "Nothing to read" << endl;
			exit(-1);
		}
		
		oneTime = true;
	}
}