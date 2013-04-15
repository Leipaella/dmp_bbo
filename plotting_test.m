function plotting_test()

figure;
subplot(1,2,1);
x = 1:4;
y = x;
plot(x,y);
h = subplot(1,2,2);
sub_plotting_test(h);

end

function sub_plotting_test(h)

figure(h);

x = 1:4;
y = 4:-1:1;
for ii = 1:16
  subplot(4,4,ii);
  plot(x,y);
end



end