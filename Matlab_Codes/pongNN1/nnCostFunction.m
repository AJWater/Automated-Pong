function [J grad] = nnCostFunction(nn_params, ...
                                   input_layer_size, ...
                                   hidden_layer1_size, ...
                                   hidden_layer2_size, ...
                                   num_labels, ...
                                   X, y, lambda)
%NNCOSTFUNCTION Implements the neural network cost function for a two layer
%neural network which performs classification
%   [J grad] = NNCOSTFUNCTON(nn_params, hidden_layer_size, num_labels, ...
%   X, y, lambda) computes the cost and gradient of the neural network. The
%   parameters for the neural network are "unrolled" into the vector
%   nn_params and need to be converted back into the weight matrices. 
% 
%   The returned parameter grad should be an "unrolled" vector of the
%   partial derivatives of the neural network.
%

% Reshape nn_params back into the parameters Theta1 and Theta2, the weight matrices
% for our 2 layer neural network
Theta1 = reshape(nn_params(1:hidden_layer1_size * (input_layer_size + 1)), ...
                 hidden_layer1_size, (input_layer_size + 1));
             
Theta2 = reshape(nn_params((1 + (hidden_layer1_size * (input_layer_size + 1))): ...
                ((hidden_layer1_size * (input_layer_size + 1)) ...
                + (hidden_layer2_size * (hidden_layer1_size + 1)))), ...
                 hidden_layer2_size, (hidden_layer1_size + 1));             

Theta3 = reshape(nn_params((1 + ((hidden_layer1_size * (input_layer_size + 1)) ...
                + (hidden_layer2_size * (hidden_layer1_size + 1)))):end), ...
                 num_labels, (hidden_layer2_size + 1));

% Setup some useful variables
m = size(X, 1);
         
% You need to return the following variables correctly 
J = 0;
Theta1_grad = zeros(size(Theta1));
Theta2_grad = zeros(size(Theta2));
Theta3_grad = zeros(size(Theta3));

% ====================== YOUR CODE HERE ======================
% Instructions: You should complete the code by working through the
%               following parts.
%
% Part 1: Feedforward the neural network and return the cost in the
%         variable J. After implementing Part 1, you can verify that your
%         cost function computation is correct by verifying the cost
%         computed in ex4.m
%
% Part 2: Implement the backpropagation algorithm to compute the gradients
%         Theta1_grad and Theta2_grad. You should return the partial derivatives of
%         the cost function with respect to Theta1 and Theta2 in Theta1_grad and
%         Theta2_grad, respectively. After implementing Part 2, you can check
%         that your implementation is correct by running checkNNGradients
%
%         Note: The vector y passed into the function is a vector of labels
%               containing values from 1..K. You need to map this vector into a 
%               binary vector of 1's and 0's to be used with the neural network
%               cost function.
%
%         Hint: We recommend implementing backpropagation using a for-loop
%               over the training examples if you are implementing it for the 
%               first time.
%
% Part 3: Implement regularization with the cost function and gradients.
%
%         Hint: You can implement this around the code for
%               backpropagation. That is, you can compute the gradients for
%               the regularization separately and then add them to Theta1_grad
%               and Theta2_grad from Part 2.
%
ytemp = zeros(m , num_labels);
for i=1:m
    a = 1:num_labels;
    b = y(i);
    ytemp(i,:) = a==b;
end

a1 = [ones(m,1) X]; 
A1 =  sigmoid(a1*Theta1');
a2 = [ones(size(A1,1),1) A1];
A2 = sigmoid(a2*Theta2');
a3 = [ones(size(A2,1),1) A2];
h =  sigmoid(a3*Theta3');  %5000x10      
% [q,p] = max(A, [], 2)
Theta1Temp = Theta1;
Theta2Temp = Theta2;
Theta3Temp = Theta3;
Theta1Temp(:,1) = 0;
Theta2Temp(:,1) = 0;
Theta3Temp(:,1) = 0;
T1 = Theta1Temp.^2;
T2 = Theta2Temp.^2;
T3 = Theta3Temp.^2;

% ytemp 5000x10

cost = ((ytemp'*(log(h))+(1-ytemp)'*log(1-h)));  
%10x10   10x5000   5000x10  +   10x5000      5000x10
I = eye(num_labels);
costDiag = I.*cost;
J = -(1/m)*sum(sum(costDiag)) + ((lambda/(2*m))*(sum(sum(T1))+(sum(sum(T2))+(sum(sum(T3))))));

%    theta1 25x401      10x26 theta2
Delta1 = 0;
Delta2 = 0;
Delta3 = 0;
%Theta2;
Theta2short = Theta2(:,2:end); % 10x25
Theta3short = Theta3(:,2:end);

X = [ones(m,1) X];  % 5000x401

for t = 1:m
    a_1 = 0;
    a_2 = 0;
    a_3 = 0;
    h = 0;
    z_2 = 0;
    z_3 = 0;
    z_4 = 0;
    A2 = 0;
    A3 = 0;
    gPrimeZ_2 = 0;
    gPrimeZ_3 = 0;
    d4 = 0;
    d3 = 0;
    d2 = 0;
   a_1 = X(t,:); %1x401
  % fprintf('size of a_1 \n');
  % size(a_1)
   z_2 =  a_1*Theta1'; %1x25
   gPrimeZ_2 = sigmoidGradient(z_2); % 1x25
   A2 = sigmoid(z_2);
   a_2 = [1 A2]; %1x26
  % fprintf('size of a_2 \n');
  % size(a_2)
   z_3 =  a_2*Theta2'; %1x25
   gPrimeZ_3 = sigmoidGradient(z_3); % 1x25
   A3 = sigmoid(z_3);
   a_3 = [1 A3]; %1x26
  
   z_4 =  a_3*Theta3';  %1x10
   h = sigmoid(z_4);
  % fprintf('size of h \n');
  % size(h)
   d4 = h - ytemp(t,:); %1x10
   d3 = (d4*Theta3short); %1x25
   d3 = d3.*gPrimeZ_3; %1x25
   d2 = (d3*Theta2short); %1x25
   d2 = d2.*gPrimeZ_2; %1x25
  % fprintf('size of d2 \n');
  % size(d2)
   Delta1 = Delta1 + d2'*a_1; % 25x401
  % fprintf('size of Delta1 \n');
  % size(Delta1)
   Delta2 = Delta2 + d3'*a_2;
   Delta3 = Delta3 + d4'*a_3; % 10x26
end

reg1 = (lambda/m)*Theta1Temp;
reg2 = (lambda/m)*Theta2Temp;
reg3 = (lambda/m)*Theta3Temp;

D_1 = Delta1./m; % 25x401
D_2 = Delta2./m; % 10x26
D_3 = Delta3./m;
Theta1_grad = D_1 + reg1; % 25x401
Theta2_grad = D_2 + reg2; % 10x26
Theta3_grad = D_3 + reg3;



% -------------------------------------------------------------

% =========================================================================

% Unroll gradients
grad = [Theta1_grad(:) ; Theta2_grad(:) ; Theta3_grad(:)];


end
