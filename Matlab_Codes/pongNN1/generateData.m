%load('pongTraining3'); %when training left paddle
load('pongTraining4');  %when training right paddle
OutputData = ModifiedPong03();
max(OutputData(:,3))
min(OutputData(:,3))
dataInput = input('Do you want to input data to data file? 1 for yes, 0 for no ')
if dataInput==1
    %X1 = [X1; OutputData(:,1:6)];
    %y1 = [y1; OutputData(:,7)+2];
    %save('pongTraining4.mat', 'X1','y1')
    X1test = [X1test; OutputData(:,1:6)];
    y1test = [y1test; OutputData(:,7)+2];
    %save('pongTraining4.mat', 'X1test','y1test')
    %X3 = [X3; OutputData(:,1:6)];
    %X3 = [X3; OutputData(:,1:5)];
    %X4 = [X4; OutputData(:,1:5)];
    %y3 = [y3; OutputData(:,7)+2];
    %y2 = [y2; OutputData(:,6)+2];
    %y4 = [y4; OutputData(:,6)+2];
    %X5 = [X5; OutputData(:,1:5)];
    %y5 = [y5; OutputData(:,6)+2];
    %save('pongTraining2.mat', 'X', 'y','X2','y2','X3','y3','Xorig','yorig','X4','y4','y5','X5')
   % X2 = X3;
   % y2 = y3;
   % X1 = X3;
   % X1(:,1) = X1(:,1) * -1;
   % X1(:,4) = X1(:,4) * -1;
   % y1 = y3;
   % save('pongTraining3.mat', 'X','X1','X2','X3','y','y1','y2','y3')
   save('pongTraining4.mat', 'X1test','y1test','X2test','y2test')
else
    fprintf('Learn how to play!\n');
end
