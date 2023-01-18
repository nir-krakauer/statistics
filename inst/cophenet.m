## Copyright (C) 2021 Stefano Guidoni <ilguido@users.sf.net>
##
## This file is part of the statistics package for GNU Octave.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {statistics} [@var{c}, @var{d}] = cophenet (@var{Z}, @var{y})
##
## Compute the cophenetic correlation coefficient.
##
## The cophenetic correlation coefficient @var{C} of a hierarchical cluster tree
## @var{Z} is the linear correlation coefficient between the cophenetic
## distances @var{d} and the euclidean distances @var{y}.
## @tex
## \def\frac#1#2{{\begingroup#1\endgroup\over#2}}
## $$ c = \frac {\sum _{i<j}(y(i,j)-{\bar {y}})(d(i,j)-{\bar {d}})}{\sqrt
## {[\sum _{i<j}(y(i,j)-{\bar {y}})^{2}][\sum _{i<j}(d(i,j)-{\bar {d}})^{2}]}}$$
## @end tex
##
## It is a measure of the similarity between the distance of the leaves, as seen
## in the tree, and the distance of the original data points, which were used to
## build the tree.  When this similarity is greater, that is the coefficient is
## closer to 1, the tree renders an accurate representation of the distances
## between the original data points.
##
## @var{Z} is a hierarchical cluster tree, as the output of @code{linkage}.
## @var{y} is a vector of euclidean distances, as the output of @code{pdist}.
##
## The optional output @var{d} is a vector of cophenetic distances, in the same
## lower triangular format as @var{y}.  The cophenetic distance between two data
## points is the height of the lowest common node of the tree.
##
## @seealso{cluster, dendrogram, inconsistent, linkage, pdist, squareform}
## @end deftypefn

function [c, d] = cophenet (Z, y)

  ## input check
  ## not used by Octave 7+
  if (nargin != 2)
    print_usage ();
  endif

  ## Z must be a tree
  [m w] = size (Z);
  if ((w != 3) || (! isnumeric (Z)) || ...
      (! (max (Z(end,1:2)) == m * 2)))
    error ("cophenet: Z must be a matrix as generated by the linkage function");
  end

  ## data set size
  n = m + 1;

  ## y must be a vector of distances
  if ((! isnumeric (y)) || (length (y) != (n - 1) * n / 2))
    error ("cophenet: y must be a vector of euclidean distances");
  end

  ## main

  ## compute the cophenetic distances d
  d = zeros (1, length (y));
  N = sparse ((m - 1), m); # to keep track of the leaves from each branch
  for i = 1 : m
    l_n = Z(i, 1);
    r_n = Z(i, 2);

    if (l_n > n)
      l_v = nonzeros (N(l_n - n, :)); # the list of leaves from the left branch
    else
      l_v = l_n;
    endif

    if (r_n > n)
      r_v = nonzeros (N(r_n - n, :)); # the list of leaves from the right branch
    else
      r_v = r_n;
    endif

    j_max = length (l_v);
    k_max = length (r_v);
    ## keep track of the leaves in each sub-branch, i.e. node;
    ## this does not matter for the last node, which includes all leaves
    if (i < m)
      N(i, 1 : (j_max + k_max)) = [l_v' r_v'];
    endif

    for j = 1 : j_max
      for k = 1: k_max
        ## d is in the same format as y
        if (l_v(j) < r_v(k))
          index = (l_v(j) - 1) * m - sum (1 : (l_v(j) - 2)) + (r_v(k) - l_v(j));
        else
          index = (r_v(k) - 1) * m - sum (1 : (r_v(k) - 2)) + (l_v(j) - r_v(k));
        endif
        d(index) = Z(i, 3);
      endfor
    endfor
  endfor

  ## compute the cophenetic correlation c
  y_mean = mean (y);
  z_mean = mean (d);

  Y_sigma = y - y_mean;
  Z_sigma = d - z_mean;

  c = sum (Z_sigma .* Y_sigma) / sqrt (sum (Y_sigma .^ 2) * sum (Z_sigma .^ 2));

endfunction


## Test input validation
%!error cophenet ()
%!error <Z must be .*> cophenet (ones (2,2), 1)
%!error <y must be .*> cophenet ([1 2 1], "a")
%!error <y must be .*> cophenet ([1 2 1], [1 2])

## Demonstration
%!demo "usage";
%! X = randn (10,2);
%! y = pdist (X);
%! Z = linkage (y, "average");
%! cophenet (Z, y)

