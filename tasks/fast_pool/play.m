
x_0 = 5; % cm
y_0 = -40; % cm
theta = pi/4; % radians
r = 3;
v_0 = 2; % units of cm/s
mu = 0.2;

x = x_0:0.1:50;
y = y_0 + tan(theta) * (x - x_0 + r/sin(theta));
y2 = y_0 + tan(theta) * (x - x_0 - r/sin(theta));

plot(x, y);
axis equal
hold on
plot(x,y2);


%ball
x_b = 35;
y_b = -5;
hold on
t = 0:pi/100: 2*pi;
plot(x_b + cos(t)*r, y_b +sin(t)*r);



slope = tan(theta);
intercept = y_0 + tan(theta) * (- x_0 + r/sin(theta));
y2 = y_0 + tan(theta) * (x - x_0 - r/sin(theta));
[x_i y_i] = linecirc(slope,intercept,x_b,y_b,r);
intercept = y_0 + tan(theta) * (x_0 - r/sin(theta));
[x_i2 y_i2] = linecirc(slope,intercept,x_b,y_b,r);

if isnan(x_i) & isnan(x_i2);
    %means that there is no intersection, so check for wall intersections
else
    %means there was an intersection, so compute new equations. First find
    %the distance to see if you had enough force to get that far.
    distance = sqrt((x_i - x_0).^2 + (y_i - y_0).^2);
    [distance which] = min(distance);
    x_i = x_i(which);
    y_i = y_i(which);
    dt = 0.1;
    t = 0:dt:10; % every tenth second
    a = -mu*9.8*dt;
    v = v_0 + (1:length(t)).*a;
    v(v<0) = 0;
    d = zeros(1,length(t));
    for i = 2:length(t)
        d(i) = d(i-1) + v(i-1);
    end
    if max( d > distance) > 0
        %it has enough power to get to the ball
        %so we know the intersection point. 
    else 
        %it will stop before it hits the ball, so find stopping point and
        %return.
        final_d = d(end);
        final_x = x_0 + cos(theta)*final_d;
        final_y = y_0 + sin(theta)*final_d;
        plot(final_x, final_y, 'rx');
        
    end
end

