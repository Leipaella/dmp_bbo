function new = clone(this) %#ok<INUSD>
% Use it to create a copy of an handle object
save('temp.mat', 'this');
Foo = load('temp.mat');
new = Foo.this;
delete('temp.mat');
end
