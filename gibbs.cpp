#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <vector>
#include <algorithm>
#include <map>
#include <math.h>
#include <queue>
#include <random>
using namespace std;

map<char, int> mapping;
vector<vector<double> > ocrFactor(1000,vector<double>(10)); // 1 vector of size 10 for each image i
vector<vector<double> > transFactor(10,vector<double>(10)); // 10*10 table for each occurrence possibility
int n1, n2, totalVar, u;

int main(){

	random_device r1;
	mt19937 gen(r1());
	uniform_int_distribution<> dis(0,9);

	ifstream file;
	ifstream fileOCR;
	ifstream fileTrans;
	ifstream fileTruth;
	string temp;
	int a1[100],a2[100];

	char temp1[1000];

	char *c;

	
	// modelNum = 1 OCR, 2 = OCR + trans, 3 = OCR+trans+skip, 4 = complete



	file.open("./OCRdataset-2/data/data-loopsWS.dat");
	fileOCR.open("./OCRdataset-2/potentials/ocr.dat");
	fileTrans.open("./OCRdataset-2/potentials/trans.dat");
	fileTruth.open("./OCRdataset-2/data/truth-loopsWS.dat");

	int totalChar = 0;
	int correctChar = 0;
	double DLL = 0.0;
	int correctWord = 0;
	int totalWord = 0;

	// mapping of character to index
	mapping['d'] = 0;
	mapping['o'] = 1;
	mapping['i'] = 2;
	mapping['r'] = 3;
	mapping['a'] = 4;
	mapping['h'] = 5;
	mapping['t'] = 6;
	mapping['n'] = 7;
	mapping['s'] = 8;
	mapping['e'] = 9;

	int r=0, in=0;

	while(!fileOCR.eof()){
		getline(fileOCR,temp);
		strcpy(temp1, temp.c_str());

		c = strtok(temp1,"\t");
		while(c!=NULL){

			double temp = atof(c);
			c  = strtok(NULL,"\t");
			if(c==NULL){
				
				ocrFactor[r][in] = temp;

				in++;
				if(in==10){
					r++;
					in = 0;
				}

			}
		}
	}

	r = 0;
	in = 0;
	int index1, index2;
	while(!fileTrans.eof()){

		getline(fileTrans,temp);
		strcpy(temp1, temp.c_str());
		
		

		c = strtok(temp1,"\t");
		while(c!=NULL){
			

			index1 = mapping[c[0]];
			c  = strtok(NULL,"\t");
			index2 = mapping[c[0]];
			//cout<<c[0]<<"\n";
			c  = strtok(NULL,"\t");
			transFactor[index1][index2] = atof(c);
			

			c  = strtok(NULL,"\t");
			
		}
		
	}

	// start reading file

	while(!file.eof()){

		n1 = 0;
		n2 = 0;


		int a3[100],a4[100];

		getline(fileTruth,temp);
		int len = temp.length();

		for(int i=0;i<len;i++){

			a3[i] = mapping[temp[i]];
			
		}

		getline(fileTruth,temp);
		len = temp.length();

		for(int i=0;i<len;i++){

			a4[i] = mapping[temp[i]];
			
		}


		getline(file,temp);
		
		if(temp[0]=='\0')
			break;
		strcpy(temp1, temp.c_str());

		
		c = strtok(temp1,"\t");
		while(c!=NULL){

			a1[n1++] = atoi(c);
			
			c  = strtok(NULL,"\t");
			

		}

		getline(file,temp);


		strcpy(temp1, temp.c_str());

		c = strtok(temp1,"\t");
		while(c!=NULL){

			a2[n2++] = atoi(c);
			
			c  = strtok(NULL,"\t");
			
		}

		getline(file,temp);
		getline(fileTruth,temp);
		
		totalVar = n1 + n2;

		vector<vector<int> > samples;
		vector<int> tempPrev(totalVar);
		for(int i=0;i<totalVar;i++){

			tempPrev[i] = dis(gen);
			
		}
	
		int convergence = 0;
		while(convergence!=10000){
			
			convergence++;
			
			vector<int> tempSample(totalVar);
			for(int i=0;i<totalVar;i++){

				vector<double> factor(10);

				// add OCR Factor
				if(i<n1){

					for(int j=0;j<10;j++){

						factor[j] = ocrFactor[a1[i]][j];

					}

					// add skip factor

					for(int j=0;j<i;j++){

						if(a1[i] == a1[j]){

							factor[tempSample[j]] *= 5;
						}
					}

					for(int j=i+1;j<n1;j++){

						if(a1[i]==a1[j]){


							factor[tempPrev[j]] *= 5;
						}

					}
					// add trans factor
					if(i!=n1-1){

						for(int j=0;j<10;j++){

							factor[j] *= transFactor[j][tempPrev[i+1]];
						}

					}

					// add word-skip

					for(int j=0;j<n2;j++){


						if(a1[i] == a2[j]){

							factor[tempPrev[j+n1]] *= 5;
						}
					}

				}else{


					for(int j=0;j<10;j++){

						factor[j] = ocrFactor[a2[i-n1]][j];

					}

					// add skip factor

					for(int j=n1;j<i;j++){

						if(a2[i-n1] == a2[j-n1]){

							factor[tempSample[j]] *= 5;
						}

					}

					for(int j=i+1;j<totalVar;j++){

						if(a2[i-n1]==a2[j-n1]){


							factor[tempPrev[j]] *= 5;
						}

					}
					// add trans factor
					if(i!=totalVar-1){

						for(int j=0;j<10;j++){

							factor[j] *= transFactor[j][tempPrev[i+1]];
						}

					}

					// add word-skip

					for(int j=0;j<n1;j++){


						if(a2[i-n1] == a1[j]){

							factor[tempSample[j]] *= 5;
						}


					}

				}

				double z = 0.0;

				for(int j=0;j<10;j++){

					z += factor[j];
				}
				
				for(int j=0;j<10;j++){

					factor[j] /= z;
					
				}

				double randNum = ((double)rand()/(INT_MAX));

				double cumulative = 0.0;

				for(int j=0;j<10;j++){

					cumulative += factor[j];

					if(cumulative > randNum){

						tempSample[i] = j;
						break;
					}

				}

			}


			for(int j=0;j<totalVar;j++)
				tempPrev[j] = tempSample[j];


			samples.push_back(tempSample);

		}
		
		double currDLL = 1.0;
		vector<int> assignment(totalVar);
		totalWord = totalWord + 2;
		int temp1 = 0,temp2 = 0;
		
		for(int i=0;i<totalVar;i++){
			
			vector<int> count(10,0);

			for(int j=1000;j<9999;j++){

				count[samples[j][i]]++;

			}

			int maxValue = count[0], maxIndex = 0;
			double sum = 0.0;
			
			for(int j=1;j<10;j++){

				if(count[j] > maxValue){

					maxValue = count[j];
					maxIndex = j;
				}
				sum += count[j];


			}

			if(i<n1){
				currDLL *= double(count[a3[i]]/sum);

			}else{
				currDLL *= double(count[a4[i-n1]]/sum);

			}

			assignment[i] = maxIndex;
		}

		DLL += log(currDLL);
		
		
		for(int i=0;i<n1;i++){

			if(a3[i] == assignment[i]){
				temp1++;
				correctChar++;
			}
			totalChar++;
		}
		for(int i=0;i<n2;i++){

			if(a4[i] == assignment[n1+i]){
				temp2++;
				correctChar++;
			}
			totalChar++;
		}

		
		if(temp1 == n1)
			correctWord++;
		if(temp2==totalVar-n1)
			correctWord++;

		

	}
	double char_Acc = ((double)(correctChar)/(totalChar));
	DLL = DLL/(double)totalWord;
	cout<<"Char Accuracy :"<<char_Acc<<"\n";
	cout<<"DLL :"<<DLL<<"\n";
	double word_Acc = ((double)(correctWord)/(totalWord));
	cout<<"word_Acc :"<<word_Acc<<"\n";


	return 0;
	

}
