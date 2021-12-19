const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

process.env.BABEL_ENV = "development";
process.env.NODE_ENV = "development";

module.exports = {
    mode: "development",
    entry: {
        app: './src/App.js',
    },
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'js/[name].bundle.js',
        chunkFilename: 'js/[name].bundle.js',
    },
    devtool: 'inline-source-map',
    devServer: {
        static: {
            directory: path.join(__dirname, 'public'),
        },
        compress: true,
        port: 9000,
    },
    optimization: {
        moduleIds: 'deterministic',
        runtimeChunk: 'single',
        splitChunks: {
            cacheGroups: {
                vendor: {
                    test: /[\\/]node_modules[\\/]/,
                    name: 'vendors',
                    chunks: 'all'
                },
                lb: {
                    test: './src/es6/landing-skeleton.js',
                    name: 'lb',
                    chunks: 'all',
                }
            }
        }
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: "./assets/index.html",
            filename: "./index.html",
            inject: 'head',
        }),
        new MiniCssExtractPlugin({
            filename: "css/[name].bundle.css",
            chunkFilename: "css/[id].bundle.css"
        }),
        new webpack.ProvidePlugin({
            $: "jquery",
            _: "lodash",
            jQuery: "jquery",
            "window.jQuery": "jquery"
        }),
        new webpack.DefinePlugin({
            PRODUCTION: JSON.stringify(false),
        }),
    ],
    module: {
        rules: [
            {
                test: /\.?js$/,
                exclude: /(node_modules|bower_components)/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            },
            {
                test: /\.html$/,
                use: [
                    {
                        loader: "html-loader",
                        options: {
                            //minimize: true
                        }
                    }
                ]
            },
            {
                test: /\.s[ac]ss$/i,
                use: [
                    // Creates `style` nodes from JS strings
                    "style-loader",
                    // Translates CSS into CommonJS
                    "css-loader",
                    // Compiles Sass to CSS
                    "sass-loader",
                ],
            },
            {
                test: /\.(woff|woff2|eot|ttf|otf)$/,
                loader: 'file-loader',
                options: {
                    outputPath: 'fonts',
                    name: '[name].[ext]',
                },
            },
            {
                test: /\.(png|svg|jpg|gif)$/,
                loader: 'file-loader',
                options: {
                    outputPath: 'img',
                    //name: '[name].[ext]',
                },
            },
            {
                test: /\.(pcd|mp3)$/,
                loader: 'file-loader',
                options: {
                    outputPath: 'img',
                    //name: '[name].[ext]',
                },
            },
            {
                test: /\.shader$/i,
                use: 'raw-loader',
            },
        ],
    }
};
