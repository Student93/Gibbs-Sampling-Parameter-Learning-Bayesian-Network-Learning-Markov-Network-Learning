#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <vector>
#include <algorithm>
#include <map>
#include <math.h>
#include <queue>
#include <cmath>

using namespace std;

int t=0;
int totalEdges = 0;
int correctChar = 0;




int modelNum;

int adjacency[100][100];
int n1, n2, totalVar;
map<char,int> mapping;
int a1[100],a2[100];

// Data structure for Bethe Cluster Graph
//vector<vector<int> > scopeOfFactorNodes;
//vector<int> variableNodes;
vector<vector<int> > factorIndex;
vector<vector<double> > ocrFactor(1000,vector<double>(10)); // 1 vector of size 10 for each image id
vector<vector<double> > transFactor(10,vector<double>(10)); // 10*10 table for each occurrence possibility
//vector<vector<double> > initialFactors(200);
//vector<vector<double> > initialVariableFactor(200);
int vInitial[100];
int ocrAdded[100];
//vector<vector<double> > prevmsgForScope1(200);
//vector<vector<double> > prevmsgForScope2(200);
//vector<vector<double> > prevmsgFromFactorNode1(200);
//vector<vector<double> > prevmsgFromFactorNode2(200);

//vector<vector<double> > newmsgForScope1(200);
//vector<vector<double> > newmsgForScope2(200);
//vector<vector<double> > newmsgFromFactorNode1(200);
//vector<vector<double> > newmsgFromFactorNode2(200);

//vector<vector<double> > factorNodeBelief(200);
//vector<vector<double> > variableNodeBelief(200);


//vector<vector<int> > parentNodes(200);

void initializeMessages(vector<vector<int> > &scopeOfFactorNodes, vector<vector<double> > &prevmsgForScope1,vector<vector<double> > &prevmsgForScope2, vector<vector<double> > &prevmsgFromFactorNode1, vector<vector<double> > &prevmsgFromFactorNode2){

	int msgTableSize = 10; // defined on single variable always

	int l = scopeOfFactorNodes.size();

	for(int i=0;i<l;i++){

		for(int j=0;j<msgTableSize;j++){
			//prevmsgForScope1[i].clear();
			//prevmsgForScope2[i].clear();
			//prevmsgFromFactorNode1[i].clear();
			//prevmsgFromFactorNode2[i].clear();
			prevmsgForScope1[i].push_back(log(1));
			prevmsgForScope2[i].push_back(log(1));
			prevmsgFromFactorNode1[i].push_back(log(1));
			prevmsgFromFactorNode2[i].push_back(log(1));
		}


	}
	
}
 
void initializeParentNode(int index, vector<vector<int> > &scopeOfFactorNodes, vector<vector<int> > &parentNodes){


	int l = scopeOfFactorNodes.size();

	//for(int i=0;i<totalVar;i++)
	//	parentNodes[i].clear();
	
	for(int i=0;i<l;i++){

		if(find(scopeOfFactorNodes[i].begin(),scopeOfFactorNodes[i].end(),index)!=scopeOfFactorNodes[i].end()){

			parentNodes[index].push_back(i);
		}

	}
}

void initializeFactors(vector<vector<int> > &scopeOfFactorNodes, vector<vector<double> > &initialFactors, vector<vector<double> > &initialVariableFactor){


	int l = scopeOfFactorNodes.size();
	totalEdges = l * 2;



	for(int i=0;i<l;i++){

		// insert transFactor
		int pSize = scopeOfFactorNodes[i].size();
		int fSize = pow(10,pSize);
		vInitial[i] = 1;
		int flag = 0;
		for(int j=0;j<fSize;j++)
			initialFactors[i].push_back(0.0);

		if( scopeOfFactorNodes[i][0] != n1-1 && scopeOfFactorNodes[i][0] == scopeOfFactorNodes[i][1] - 1 ){
			//if(i==2)
			//	cout<<"here22\n";

			// trans factor
			if(flag == 0){

				for(int j=0;j<fSize;j++){

					initialFactors[i][j] = transFactor[factorIndex[j][0]][factorIndex[j][1]];

				}
			}

		}

		// ocr factor
		// one loop to insert if that element is first in place of factor node and then for remaining nodes will 
		// check in scope

		if(ocrAdded[scopeOfFactorNodes[i][0]]==0){
			// ocr factor not added
			
			ocrAdded[scopeOfFactorNodes[i][0]] = 1;
			int imageId;
			if(scopeOfFactorNodes[i][0]<n1){

				imageId = a1[scopeOfFactorNodes[i][0]];

			}else{

				imageId = a2[scopeOfFactorNodes[i][0]-n1];
			}

			for(int j=0;j<fSize;j++){

				initialFactors[i][j] += ocrFactor[imageId][factorIndex[j][0]];
				//if(i==2)
				//	cout<<imageId<<"\n";

			}




		}

		// check for skip factor 

		// In word One
		if(scopeOfFactorNodes[i][0] < n1 && scopeOfFactorNodes[i][1] < n1 && a1[scopeOfFactorNodes[i][0]] == a1[scopeOfFactorNodes[i][1]] ){
			flag = 0;

			for(int j=0;j<i;j++){

				if(scopeOfFactorNodes[j][0] == scopeOfFactorNodes[i][1] && scopeOfFactorNodes[j][1] == scopeOfFactorNodes[i][0]){
					flag = 1;
					break;
				}

			}
			if(flag == 0){
				//cout<<fSize<<"fsize fsize\n\n\n";
				for(int j=0;j<fSize;j++){


					if(factorIndex[j][0] == factorIndex[j][1]){

						initialFactors[i][j] += log(2);
					}
					else{

						initialFactors[i][j] += log(.1);
					}
				}
			}
		}


		// In word Two
		if(scopeOfFactorNodes[i][0] >=n1 && scopeOfFactorNodes[i][1] >= n1 && a2[scopeOfFactorNodes[i][0]-n1] == a2[scopeOfFactorNodes[i][1]-n1] ){

			flag = 0;
			for(int j=0;j<i;j++){

				if(scopeOfFactorNodes[j][0] == scopeOfFactorNodes[i][1] && scopeOfFactorNodes[j][1] == scopeOfFactorNodes[i][0]){
					flag = 1;
					break;
				}

			}
			if(flag == 0){

				for(int j=0;j<fSize;j++){


					if(factorIndex[j][0] == factorIndex[j][1]){

						initialFactors[i][j] += log(2);
					}
					else{

						initialFactors[i][j] += log(.1);
					}
				}
			}
		}


		// Word - skip factor

		if(scopeOfFactorNodes[i][0] < n1 && scopeOfFactorNodes[i][1] >= n1){

			flag = 0;
			for(int j=0;j<i;j++){

				if(scopeOfFactorNodes[j][0] == scopeOfFactorNodes[i][1] && scopeOfFactorNodes[j][1] == scopeOfFactorNodes[i][0]){
					flag = 1;
					break;
				}

			}
			if(flag == 0){

				for(int j=0;j<fSize;j++){


					if(factorIndex[j][0] == factorIndex[j][1]){

						initialFactors[i][j] += log(5);
					}
					else{

						initialFactors[i][j] += log(1);
					}
				}
			}


		}else if(scopeOfFactorNodes[i][0] >=n1 && scopeOfFactorNodes[i][1] < n1){

			flag = 0;
			for(int j=0;j<i;j++){

				if(scopeOfFactorNodes[j][0] == scopeOfFactorNodes[i][1] && scopeOfFactorNodes[j][1] == scopeOfFactorNodes[i][0]){
					flag = 1;
					break;
				}

			}
			if(flag == 0){


				for(int j=0;j<fSize;j++){


					if(factorIndex[j][0] == factorIndex[j][1]){

						initialFactors[i][j] += log(5);
					}
					else{

						initialFactors[i][j] += log(1);
					}
				}

			}

		}






	}

	for(int i=0;i<totalVar;i++){


		if(ocrAdded[i]==0){
			//cout<<"OCR Added : "<<i<<"\n";
			for(int j=0;j<l;j++){


				if(scopeOfFactorNodes[j][1]==i){

					ocrAdded[i] = 1;
					int imageId;
					if(i<n1){

						imageId = a1[i];

					}else{

						imageId = a2[i-n1];
					}
					int pSize = scopeOfFactorNodes[j].size();
					int fSize = pow(10,pSize);
					for(int k=0;k<fSize;k++){

						initialFactors[j][k] += ocrFactor[imageId][factorIndex[k][1]];

					}


					break;
				}
			}

		}
	}

	int variableFactorSize = 10;

	for(int i=0;i<totalVar;i++){

		for(int j=0;j<variableFactorSize;j++){

			initialVariableFactor[i].push_back(log(1));

		}


	}


}



double createFactorBelief(int index, vector<vector<int> > &scopeOfFactorNodes, vector<vector<double> > &factorNodeBelief, vector<vector<double> > &initialFactors, vector<vector<double> > &prevmsgForScope1, vector<vector<double> > &prevmsgForScope2){



	int pSize = scopeOfFactorNodes[index].size();
	int fSize = pow(10,pSize);
	

	double max1 = 0.0;
	double temp;
	for(int i=0;i<fSize;i++){

		temp = exp(factorNodeBelief[index][i]);
		factorNodeBelief[index][i] = 0.0;
		factorNodeBelief[index][i] += prevmsgForScope1[index][factorIndex[i][0]];
		factorNodeBelief[index][i] += prevmsgForScope2[index][factorIndex[i][1]];
		//cout<<prevmsgForScope1[index][factorIndex[i][0]]<<" "<<prevmsgForScope1[index][factorIndex[i][1]]<<"\n";
		//cout<<factorNodeBelief[index][i]<<"\n";
		factorNodeBelief[index][i] += initialFactors[index][i];

		temp = abs(temp-exp(factorNodeBelief[index][i]));
		if(temp > max1)
			max1 = temp;

	}


	return max1;
}


double createVariableBelief(int index, vector<vector<double> > &variableNodeBelief, vector<vector<int> > &scopeOfFactorNodes, vector<vector<double> > &prevmsgFromFactorNode1, vector<vector<double> > &prevmsgFromFactorNode2){


	int variableFactorSize = 10;
	//variableNodeBelief.clear();
	int l = scopeOfFactorNodes.size();
	vector<double> tempFactor(variableFactorSize);
	for(int i=0;i<variableFactorSize;i++){

		tempFactor[i] = exp(variableNodeBelief[index][i]);
		variableNodeBelief[index][i] = 0.0;

	}



	for(int i=0;i<l;i++){

		// check in scope of all factors 

		if(scopeOfFactorNodes[i][0]==index){
			
			for(int j=0;j<variableFactorSize;j++){

				variableNodeBelief[index][j] += prevmsgFromFactorNode1[i][j];
			}


		}else if(scopeOfFactorNodes[i][1]==index){
			
			for(int j=0;j<variableFactorSize;j++){

				variableNodeBelief[index][j] += prevmsgFromFactorNode2[i][j];
			}


		}


	}

	double max1 = 0.0;
	for(int i=0;i<variableFactorSize;i++){

		if(max1 < abs(tempFactor[i]-exp(variableNodeBelief[index][i])))
			max1 = abs(tempFactor[i]-exp(variableNodeBelief[index][i]));


	}


return max1;


}

double DLL = 0.0;

int correctWord = 0;

int totalChar =0;

int main(){


	ifstream file;
	ifstream fileOCR;
	ifstream fileTrans;
	ifstream fileTruth;

	string temp;
	
	cin>>modelNum;

	int a3[100],a4[100];
	char temp1[1000];

	char *c;



	file.open("./OCRdataset-2/data/data-loopsWS.dat");
	fileOCR.open("./OCRdataset-2/potentials/ocr.dat");
	fileTrans.open("./OCRdataset-2/potentials/trans.dat");
	fileTruth.open("./OCRdataset-2/data/truth-loopsWS.dat");

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

	// Reading Trans Factor
	int index1, index2;
	while(!fileTrans.eof()){

		getline(fileTrans,temp);
		strcpy(temp1, temp.c_str());
		
		

		c = strtok(temp1,"\t");
		while(c!=NULL){

			index1 = mapping[c[0]];
			c  = strtok(NULL,"\t");
			index2 = mapping[c[0]];
			c  = strtok(NULL,"\t");
			transFactor[index1][index2] = log(atof(c));

			c  = strtok(NULL,"\t");
			
		}

	}
	/*
	for(int i=0;i<10;i++){

		for(int j=0;j<10;j++){

			cout<<transFactor[i][j]<<" ";
		}
		cout<<"\n";
	}
	//exit(0);
	*/
	// Insert OCR factor Node 10*1 because Image Id is fixed
	int r=0, in=0;

	while(!fileOCR.eof()){
		getline(fileOCR,temp);
		strcpy(temp1, temp.c_str());

		

		c = strtok(temp1,"\t");
		while(c!=NULL){

			double temp = atof(c);
			c  = strtok(NULL,"\t");
			if(c==NULL){
				
				ocrFactor[r][in] = log(temp);
				
				in++;
				if(in==10){
					r++;
					in = 0;
				}

			}
		}
	}


	vector<int> genIndex(2);
	genIndex[0] = 0;
	genIndex[1] = 0;
	int pSize = 2;


	int factorSize = pow(10, pSize);

	for(int i=0;i<factorSize;i++){


		factorIndex.push_back(genIndex);

		genIndex[1]++;
		

		if(genIndex[1]==10){
			genIndex[0]++;
			genIndex[1] = 0;
		}
	}

int ccounter = 0;	
while(!file.eof()){


	vector<vector<int> > scopeOfFactorNodes;
	vector<int> variableNodes;
	//vector<vector<int> > factorIndex;

	vector<vector<double> > initialFactors(200);
	vector<vector<double> > initialVariableFactor(200);
	
	vector<vector<double> > prevmsgForScope1(200);
	vector<vector<double> > prevmsgForScope2(200);
	vector<vector<double> > prevmsgFromFactorNode1(200);
	vector<vector<double> > prevmsgFromFactorNode2(200);

	vector<vector<double> > newmsgForScope1(200);
	vector<vector<double> > newmsgForScope2(200);
	vector<vector<double> > newmsgFromFactorNode1(200);
	vector<vector<double> > newmsgFromFactorNode2(200);

	vector<vector<double> > factorNodeBelief(200);
	vector<vector<double> > variableNodeBelief(200);


	vector<vector<int> > parentNodes(200);



	ccounter++;
	n1 = 0;
	n2 = 0;
		//getline(file,temp);getline(file,temp);getline(file,temp);

		getline(file,temp);
		strcpy(temp1, temp.c_str());

		if(temp[0]=='\0')
			break;

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
		
		totalVar = n1 + n2;


		for(int i=0;i<n1+n2;i++){

			for(int j=0;j<n1+n2;j++){

				adjacency[i][j] = 0;
			}
		}


		// adding trans edge

		if(modelNum!=1){

		for(int i=0;i<n1-1;i++){

			adjacency[i][i+1] = 1;
			//adjacency[i+1][i] = 1;

		}

		for(int i=0;i<n2-1;i++){

			adjacency[n1+i][n1+i+1] = 1;
			//adjacency[n1+i+1][n1+i] = 1;
			
		}
		

		// skip factor edge

		if(modelNum!=2){

		for(int i=0;i<n1-1;i++){
			for(int j=i+1;j<n1;j++){

				if(a1[i]==a1[j]){
					adjacency[i][j] = 1;
					//adjacency[j][i] = 1;

				}
			}
		}

		for(int i=0;i<n2-1;i++){
			for(int j=i+1;j<n2;j++){

				if(a2[i]==a2[j]){
					adjacency[n1+i][n1+j] = 1;
					//adjacency[n1+j][n1+i] = 1;
					
				}
			}
		}

		// word - skip factor
		if(modelNum!=3){

		for(int i=0;i<n1;i++){

			for(int j=0;j<n2;j++){

				if(a1[i]==a2[j]){

					adjacency[i][n1+j] = 1;
					//adjacency[n1+j][i] = 1;

				}
			}
		}
		}
		}
		}
		vector<int> tempFactor;
		scopeOfFactorNodes.clear();


		for(int i=0;i<totalVar;i++){
			tempFactor.clear();
			for(int j=0;j<totalVar;j++){

				if(adjacency[i][j]==1){

					tempFactor.push_back(i);
					tempFactor.push_back(j);
					scopeOfFactorNodes.push_back(tempFactor);
					tempFactor.clear();
				}
				

			}
		}

		variableNodes.clear();
		int l = scopeOfFactorNodes.size();
		
		
		
		//cout<<"\n\nVariable Nodes :\n";
		for(int i=0;i<totalVar;i++)
			variableNodes.push_back(i);

		//for(int i=0;i<totalVar;i++)
		//	cout<<variableNodes[i]<<"\n";

		//cout<<"\n\n\n";
		

		// Belief propagation algorithm

		for(int i=0; i<l;i++)
			vInitial[i] = 0;

		for(int i=0;i<totalVar;i++)
			ocrAdded[i] = 0;
		


	
		

		initializeMessages(scopeOfFactorNodes, prevmsgForScope1, prevmsgForScope2, prevmsgFromFactorNode1, prevmsgFromFactorNode2);
		
		


		initializeFactors(scopeOfFactorNodes, initialFactors, initialVariableFactor);

		//exit(0);


		if(modelNum == 1){
			int assignment[totalVar];

			for(int i=0;i<totalVar;i++){

				int maxIndex  = 0;
				if(i<n1){
					double maxValue = exp(ocrFactor[a1[i]][0]);
					double z = maxValue;
					

					for(int j=1;j<10;j++){
						double potentialMax = exp(ocrFactor[a1[i]][j]);
						z += potentialMax;
						
						if(potentialMax > maxValue){

							maxValue = potentialMax;
							maxIndex = j;
						}

					}

					double num = exp(ocrFactor[a1[i]][a3[i]]);
					num /=z;
					

					DLL += log(num);

					assignment[i] = maxIndex;


				}else{

						double maxValue = exp(ocrFactor[a2[i-n1]][0]);
						double z = maxValue;

						for(int j=1;j<10;j++){
							double potentialMax = exp(ocrFactor[a2[i-n1]][j]);
							z += potentialMax;
							if(potentialMax > maxValue){

								maxValue = potentialMax;
								maxIndex = j;
							}

						}

						double num = exp(ocrFactor[a2[i-n1]][a4[i-n1]]);
						num /=z;
						DLL += log(num);

						assignment[i] = maxIndex;




				}


			}

			getline(fileTruth,temp);
			int len = temp.length();
			int prev = correctChar;
			for(int i=0;i<len;i++){

				a3[i] = mapping[temp[i]];
				
				if(a3[i] == assignment[i])
					correctChar++;
				totalChar++;
			}
			if((correctChar-prev)==len)
				correctWord++;


			getline(fileTruth,temp);
			len = temp.length();

			prev = correctChar;

			for(int i=0;i<len;i++){

				a4[i] = mapping[temp[i]];
				
				if(a4[i]==assignment[n1+i])
					correctChar++;
				totalChar++;
			}
			if((correctChar-prev)==len)
				correctWord++;

			getline(fileTruth,temp);


			

			
			getline(file,temp);





		}else{

			l = scopeOfFactorNodes.size();

			for(int i=0;i<l;i++){

				for(int j=0;j<100;j++)
					factorNodeBelief[i].push_back(0.0);

				createFactorBelief(i, scopeOfFactorNodes, factorNodeBelief, initialFactors, prevmsgForScope1, prevmsgForScope2);

			}

			for(int i=0;i<totalVar;i++){

				for(int j=0;j<10;j++)
					variableNodeBelief[i].push_back(0.0);

				createVariableBelief(i,variableNodeBelief, scopeOfFactorNodes, prevmsgFromFactorNode1, prevmsgFromFactorNode2);
			}


			for(int i=0;i<totalVar;i++){
				
				initializeParentNode(i, scopeOfFactorNodes, parentNodes);
			}

			/*
			for(int i=0;i<l;i++){

				int k = initialFactors[i].size();
				for(int j=0;j<k;j++)
					cout<<initialFactors[i][j]<<" ";
				cout<<"\n\n\n\n";

			}
			*/
			//exit(0);
			

			/*
			for(int i=0;i<l;i++){

					for(int j=0;j<100;j++){

						cout<<factorNodeBelief[i][j]<<"\n";
					}
					cout<<"\n\n\n\n";
			}


			cout<<"AFTER :";
			
			
			for(int i=0;i<totalVar;i++){


				for(int j=0;j<10;j++){

					cout<<variableNodeBelief[i][j]<<" ";
				}
				cout<<"\n\n\n\n";

			}
			*/
			
			/*
			cout<<"start\n";
			for(int i=0;i<l;i++){

				for(int j=0;j<100;j++){

					cout<<factorNodeBelief[i][j]<<" ";
				}
				cout<<"\n\n\n\n";
			}

			cout<<" herehee\n";
			
			*/
			/*
			cout<<"Initial"<<ccounter<<"\n";
			for(int i=0;i<l;i++){

				for(int j=0;j<100;j++){

					cout<<initialFactors[i][j]<<" ";
				}
				cout<<"\n\n\n\n";
			}
			
			//exit(0);
			*/
			t= 0;
			while(true){


				

				// update messages
				vector<double> tempMsg; 
				int msgSize=10;
				map<string,double> valueToSubtract; 
				factorSize = 100;
				vector<double> tempBelief;
				
				for(int i=0;i<l;i++){
					
					// update
					// msgFromFactorNode1
					for(int j=0;j<msgSize;j++){

						valueToSubtract[to_string(j)] = prevmsgForScope1[i][j];
						tempMsg.push_back(0.0);
					}
					tempBelief = factorNodeBelief[i];

					for(int j=0;j<factorSize;j++){

						tempBelief[j] -= valueToSubtract[to_string(factorIndex[j][0])]; 

					}
					//exit(0);
					int counter = 0;
					for(int j=0;j<factorSize;j++){

						if((j!=0 && j%10==0)){
							tempMsg[counter] = log(tempMsg[counter]);
							counter++;
						}

						tempMsg[counter] += exp(tempBelief[j]);

						if(j==factorSize-1){

							tempMsg[counter] = log(tempMsg[counter]);
						}

					}

					newmsgFromFactorNode1[i] = tempMsg;
					tempMsg.clear();
					valueToSubtract.clear();
					
					// msgFromFactorNode2
					for(int j=0;j<msgSize;j++){

						valueToSubtract[to_string(j)] = prevmsgForScope2[i][j];
						
						tempMsg.push_back(0.0);
					}

					
					
					tempBelief = factorNodeBelief[i];

					for(int j=0;j<factorSize;j++){

						tempBelief[j] -= valueToSubtract[to_string(factorIndex[j][1])]; 

					}

					
					for(int j=0;j<msgSize;j++){


						for(int k=j;k<factorSize;k=k+msgSize)
							tempMsg[j] += exp(tempBelief[k]);
						tempMsg[j] = log(tempMsg[j]);

					}


					newmsgFromFactorNode2[i] = tempMsg;
					tempMsg.clear();
					valueToSubtract.clear();

					
					
				}


				
				for(int i=0;i<totalVar;i++){	

					int parentSize = parentNodes[i].size();

					for(int j=0;j<parentSize;j++){

						if(scopeOfFactorNodes[parentNodes[i][j]][0] == i){
							// update msgForScope1

							for(int k=0;k<msgSize;k++){

								valueToSubtract[to_string(k)] = prevmsgFromFactorNode1[parentNodes[i][j]][k];
								
								
							}

							
							
							tempBelief = variableNodeBelief[i];

							for(int j=0;j<msgSize;j++){

								tempBelief[j] -= valueToSubtract[to_string(j)]; 
								//cout<<tempBelief[j]<<" ";

							}

							//cout<<"\n\n";

							
							


							newmsgForScope1[parentNodes[i][j]] = tempBelief;
							tempBelief.clear();
							valueToSubtract.clear();


						}else if(scopeOfFactorNodes[parentNodes[i][j]][1] == i){
							// update msgForScope2



							for(int k=0;k<msgSize;k++){

								valueToSubtract[to_string(k)] = prevmsgFromFactorNode2[parentNodes[i][j]][k];
								
								
							}

							
							
							tempBelief = variableNodeBelief[i];

							for(int j=0;j<msgSize;j++){

								tempBelief[j] -= valueToSubtract[to_string(j)]; 
								//cout<<tempBelief[j]<<" ";

							}
							//cout<<"\n\n";

							
							


							newmsgForScope2[parentNodes[i][j]] = tempBelief;
							tempBelief.clear();
							valueToSubtract.clear();



						}

					}

				}


				for(int i=0;i<l;i++){


					prevmsgForScope1[i] = newmsgForScope1[i];
					prevmsgForScope2[i] = newmsgForScope2[i];
					prevmsgFromFactorNode1[i] = newmsgFromFactorNode1[i];
					prevmsgFromFactorNode2[i] = newmsgFromFactorNode2[i];
					
				}

				double maxDiff = 0.0;

				double ttemp[100];

				/*for(int j=0;j<100;j++){

						ttemp[j] = factorNodeBelief[2][j];
				}*/

				for(int i=0;i<l;i++){

					double max1 = createFactorBelief(i, scopeOfFactorNodes, factorNodeBelief, initialFactors, prevmsgForScope1, prevmsgForScope2);
					//cout<<"Max1 : "<<max1<<"\n\n";
					if(maxDiff < max1)
						maxDiff = max1;

				}

				for(int i=0;i<totalVar;i++){

					double max2 = createVariableBelief(i,variableNodeBelief, scopeOfFactorNodes, prevmsgFromFactorNode1, prevmsgFromFactorNode2);
					//cout<<"Max2 :"<<max2<<"\n";
					if(maxDiff < max2)
						maxDiff = max2;
				}

				/*
				//for(int i=0;i<l;i++){
				cout<<t<<"\n";
					for(int j=0;j<100;j++){

						cout<<factorNodeBelief[1][j]<<" "<<ttemp[j]<<" "<<abs(factorNodeBelief[2][j]-ttemp[j])<<"\n";
					}
					cout<<"\n\n\n\n";
				//}

				cout<<"\n\n\n";	
				*/
				/*
				cout<<"\n\n\n";
				for(int j=0;j<100;j++){

					cout<<factorNodeBelief[2][j]<<"\n";
				}*/

				t = t + 1;

				//cout<<t<<" "<<maxDiff<<"\n";
				
				if(maxDiff < 0.0001  )
					break;
					
			}

			//cout<<t<<"\n";

			/*
			for(int i=0;i<l;i++){

					for(int j=0;j<100;j++){

						cout<<factorNodeBelief[i][j]<<"\n";
					}
					cout<<"\n\n\n\n";
				}
			*/	
			/*
			l = scopeOfFactorNodes.size();

			for(int i=0;i<l;i++){

				for(int j=0;j<100;j++){

					cout<<factorNodeBelief[i][j]<<"\n";
				}
				cout<<"\n\n\n\n";
			}*/

			/*

			for(int i=0;i<totalVar;i++){


				for(int j=0;j<10;j++){

					cout<<variableNodeBelief[i][j]<<" ";
				}
				cout<<"\n\n\n\n";

			}
			*/
			//*/
			
			/*
			l = scopeOfFactorNodes.size();
			//for(int i=0;i<l;i++){
				
				for(int j=0;j<10;j++){

					cout<<prevmsgFromFactorNode1[0][j]<<" ";
				}
				cout<<"\n";

				for(int j=0;j<10;j++){

					cout<<prevmsgFromFactorNode1[1][j]<<" ";
				}
				cout<<"\n";

				for(int j=0;j<10;j++){

					cout<<prevmsgFromFactorNode1[2][j]<<" ";
				}
				cout<<"\n";
				

				for(int j=0;j<10;j++){

					cout<<prevmsgForScope1[i][j]<<" ";
				}
				cout<<"\n";

				for(int j=0;j<10;j++){

					cout<<prevmsgForScope2[i][j]<<" ";
				}
				cout<<"\n";
				
			
				//cout<<"\n\n\n\n\n\n";

			//}
			
			
			
			
			for(int i=0;i<totalVar;i++){

				for(int j=0;j<10;j++){

					cout<<variableNodeBelief[i][j]<<" ";
				}
				cout<<"\n";
			}
			*/
			
			
			
			vector<int> assignment(totalVar);
			for(int i=0;i<totalVar;i++){
				int index = 0;
				double tttemp = exp(variableNodeBelief[i][0]);
				double z = tttemp;
				for(int j=1;j<10;j++){
					double t1emp = exp(variableNodeBelief[i][j]);
					z += t1emp;
					if(tttemp < t1emp){

						index = j;
						tttemp = t1emp;
					}

				}
				if(i<n1){

					double num = exp(variableNodeBelief[i][a3[i]]);
					num /=z;
					DLL += log(num);

				}else{
					double num = exp(variableNodeBelief[i][a4[i-n1]]);
					num /=z;
					DLL += log(num);

				}
				assignment[i] = index;
				

			}
			

			//getline(fileTruth,temp);getline(fileTruth,temp);getline(fileTruth,temp);
			
			getline(fileTruth,temp);
			int len = temp.length();

			int prev = correctChar;
			for(int i=0;i<len;i++){

				a3[i] = mapping[temp[i]];
				//cout<<a3[i]<<" ";
				if(a3[i] == assignment[i])
					correctChar++;
				totalChar++;
			}

			if((correctChar-prev)==len)
				correctWord++;


			getline(fileTruth,temp);
			len = temp.length();

			prev = correctChar;
			for(int i=0;i<len;i++){

				a4[i] = mapping[temp[i]];
				//cout<<a4[i]<<" ";
				if(a4[i]==assignment[n1+i])
					correctChar++;
				totalChar++;
			}

			getline(fileTruth,temp);

			if((correctChar-prev)==len)
				correctWord++;
			//cout<<"\n";

			//cout<<correctChar<<"\n";
			getline(file,temp);
		}

		//if(ccounter == 1)
		//	exit(0);

		
	}
	ccounter--;

	cout<<ccounter<<"\n";

	cout<<correctChar<<"\n";
	double percent = correctChar/double(totalChar);
	cout<<"percent :"<<percent<<"\n";
	double value = double(correctWord)/(2*ccounter);
	cout<<value<<"\n";
	value = double(DLL)/(2*ccounter);
	cout<<value<<"\n";
	

	
}