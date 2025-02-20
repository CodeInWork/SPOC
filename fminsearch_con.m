function [ fitpar, fitfun ] = fminsearch_con( mfunction, mcoeff, mcoeff_lower, mcoeff_upper, options, xdata, ydata )


    [fp, ff] = fminsearch( 