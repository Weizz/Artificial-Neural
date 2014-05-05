img=imread('edge.png');
a=rgb2gray(img);
w=edge(a,'sobel','vertical');
imshow(w);
