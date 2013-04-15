function [X, Y] = billiardgame3(x,y,v,theta, teams)
%function [X,Y,Z] = billiardgame3(N,massmax,vmax,T)
%takes in a vector of locations for billiard balls in the form of 5 arrays:
% x, y, v, theta,teams

%set initial variables
N = length(x); %number of balls
w = 50; %width of board
l = 100; %length of board
rad = 5; %radius of the ball
h = rad*3; %height of the board

% mass is assumed constant across all balls
M = 10*ones(1,N);

%initial velocities
vx = cos(theta).*v;
vy = sin(theta).*v;
vz = zeros(1,N);

%initial positions
X0 = x;
Y0 = y;



%generates and plays a game of billiards with N randomly placed billiard
%balls on a table.  The balls have random mass between 0 and massmax,
%velocity between 0 and vmax, and plays for T seconds, with timestep .01.

tstep = 0.05;
T = 10; %max time, but will return when movement stops.

[X,Y] = billiards3(w,l,h,M,vx,vy,vz,X0,Y0,T,rad,tstep);


%figure

%billiardplayer3(X,Y,Z,0.01,w,l,h,teams)
end


function [v1n,v2n] = collide3(m1,m2,v1,v2)
%solves the conservation of velocity and momentum for two balls of mass m1
%and m2 colliding at velocities v1 and v2, and returns their new
%velocities.
C1 = (m1-m2)/(m1+m2);
C2 = (2*m2)/(m1+m2);
C3 = (2*m1)/(m1+m2);
v1n = C1*v1+C2*v2;
v2n = -C1*v2+C3*v1;


end

function [v1x v1y v2x v2y] = collide2(x1, y1, x2, y2, v1x, v1y, v2x, v2y)

theta = atan2(y2 - y1, x2 - x1);

v1 = sqrt(v1x^2 + v1y^2);
t1 = atan2(v1y, v1x);
v2 = sqrt(v2x^2 + v2y^2);
t2 = atan2(v2y, v2x);
delx = x2 - x1;
dely = y2 - y1;
delmag = sqrt(delx^2 + dely^2);

%normal component
v1xn = cos(t1 - theta)*v1*delx/delmag;
v1yn = cos(t1 - theta)*v1*dely/delmag;
%tangential componant
v1xt = v1x - v1xn;
v1yt = v1x - v1yn;

%normal component
v2xn = cos(t2 - theta)*v2*delx/delmag;
v2yn = cos(t2 - theta)*v2*dely/delmag;
%tangential componant
v2xt = v2x - v2xn;
v2yt = v2x - v2yn;

%swap the two values of the normal velocity for ball 1 and 2, since have
%the same mass.
swap = v1xn;
v1xn = v2xn;
v2xn = swap;

swap = v1yn;
v1yn = v2yn;
v2yn = swap;


%t1 = atan2(v1yn,v1xn);
%t2 = atan2(v2yn,v2xn);

v1x = v1xn + v1xt;
v1y = v1yn + v1yt;

v2x = (v2xn + v2xt);
v2y = (v2yn + v2yt);


end

function [A,W] = collisions3(X,Y,rad,w,l)
%takes vectors X, Y, and Z where each entry contains the x- or y-position of
%a billiard ball and returns an n x 2 matrix A containing the indices where
%there is a collision (assuming balls have radius rad),
%and a matrix W containing the indices of which balls collided with walls
%in a w x l x h rectangle
W = [];
C = X>=w; %oddly, I can't find a way to make this code nicer. Checks collisions with walls
C = +C;
D = Y>=l;
D = +D;
E = X<=0;
E = +E;
F = Y<=0;
F = +F;
C = C+D+E+F;


W = find(C);

X = ones(length(X),1)*X;
Y = ones(length(Y),1)*Y;

B = sqrt((X-X.').^2+(Y-Y.').^2); %a matrix whose (i,j)th entry is the distance between particle i and particle j
B = B<rad;
A = [];
for j = 1:size(B,2)
  for k = 1:j-1
    if B(k,j)==1
      A = [A;k,j];
    end
  end
end
end

function [X,Y] = billiards3(w,l,h,M,vx,vy,vz,X0,Y0,T,rad,tstep)
%simulates billiards with elastic collisions on a w x l billiards table.  M
%should be a vector recording the (positive) masses of the billiard balls
%(the function will create as many balls as the length of M).  vx, vy, X0,
%Y0 will similarly be vectors giving the initial x and y velocities of each
%billiard ball, and then initial positions.  The program runs for T seconds
%with time step tstep.  A reasonable setup is
%billiards(9,4.5,randi(10,1,9),3*rand(1,9),3*rand(1,9),.5+randi(8,1,9),.4+ran
%di(4,1,9),5,.2,.01)

X = zeros(floor(T/tstep),length(M)); %initialize the three position arrays, one column per particle
Y = zeros(floor(T/tstep),length(M));

X(1,:) = X0; %set initial position
Y(1,:) = Y0;

k = 2;
while any(abs(vx) > 0.001 | abs(vy) > 0.001)
  vx = vx.*0.995;
  vy = vy.*0.995;
  
  tryxpos = X(k-1,:)+tstep*vx; %here we check if any collisions will happen in the next step
  tryypos = Y(k-1,:)+tstep*vy;
  
  [A,W] = collisions3(tryxpos,tryypos,rad,w,l);
  for j = 1:size(A,1)
    %     x1 = X(A(j,1));
    %     y1 = Y(A(j,1));
    %     x2 = X(A(j,2));
    %     y2 = Y(A(j,2));
    %     v1x = vx(A(j,1));
    %     v1y = vy(A(j,1));
    %     v2x = vx(A(j,2));
    %     v2y = vy(A(j,2));
    %     [v1x v1y v2x v2y] = collide2(x1, y1, x2, y2, v1x, v1y, v2x, v2y);
    %     vx(A(j,1)) = v1x;
    %     vx(A(j,2)) = v2x;
    %     vy(A(j,1)) = v1y;
    %     vy(A(j,2)) = v2y;
    
    [vx(A(j,1)),vx(A(j,2))] = collide3(M(A(j,1)),M(A(j,2)),vx(A(j,1)),vx(A(j,2))); %avoiding collisions with particles
    [vy(A(j,1)),vy(A(j,2))] = collide3(M(A(j,1)),M(A(j,2)),vy(A(j,1)),vy(A(j,2)));
  end
  
  %noise in wall collisions
  noise = rand(1);
  
  %   for j = 1:length(W)
  %     if tryxpos(W(j)) >= w || tryxpos(W(j))<=0 %avoiding collisions with walls
  %       vx(W(j)) = -vx(W(j)) + noise;
  %     elseif tryypos(W(j))>=l || tryypos(W(j))<=0
  %       vy(W(j)) = -vy(W(j)) + noise;
  %     elseif tryzpos(W(j)) >=h || tryzpos(W(j))<=0
  %       vz(W(j)) = -vz(W(j)) + noise;
  %     end
  %   end
  %
  if ~isempty(W)
    vx(W) = 0;
    vy(W) = 0;
  end
  
  
  X(k,:) = X(k-1,:)+tstep*vx;%updating the position with the “fixed” velocity vectors
  Y(k,:) = Y(k-1,:)+tstep*vy;
  k= k+1;
end
X(k:end,:) = [];
Y(k:end,:) = [];

end
