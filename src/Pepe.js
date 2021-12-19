import * as PIXI from "pixi.js";

import pepeShader from "../assets/shaders/pepe.shader";
import matrixVertShader from "../assets/shaders/matrixVertex.shader";
import matrixFragShader from "../assets/shaders/matrixFrag.shader";

import fonts from "../assets/img/captureFont.png";

export default class PepeShader {
  constructor() {
    this.fragShader = pepeShader;
    this.matrixVertShader = matrixVertShader;
    this.matrixFragShader = matrixFragShader;
  }

  initialization() {
    this.pixiApp = new PIXI.Application({
      antialias: true,
      transparent: false,
      autoDensity: true,
      resolution: 1,
    });

    document.body.appendChild(this.pixiApp.view);

    $("body").css({
      margin: 0,
      overflow: "hidden"
    });

    this.pixiApp.renderer.backgroundColor = 0xFFFFFF;
    this.pixiApp.renderer.resize(window.innerWidth, window.innerHeight);

    const shaderContainer = new PIXI.Container();
    shaderContainer.backgroundColor = 0x000000;

    const backGroundGraphics = new PIXI.Graphics();

    shaderContainer.addChild(backGroundGraphics);
    //
    //DRAW BIG BACKGROUND RECT FOR USING SHADER ON FULL SCREEN
    backGroundGraphics.beginFill(0x0000000)
      .drawRect(0, 0, window.innerWidth, window.innerHeight)
      .endFill();

    this.uniforms = {};

    this.uniforms.resolutionX = window.innerWidth ;
    this.uniforms.resolutionY = window.innerHeight;
    this.uniforms.u_time = 0;

    const texture = PIXI.Texture.from(fonts);
    texture.baseTexture.wrapMode = PIXI.WRAP_MODES.REPEAT;
    texture.baseTexture.mipmap = PIXI.MIPMAP_MODES.OFF;

    const material = new PIXI.MeshMaterial(texture, {
      program: PIXI.Program.from(this.matrixVertShader, this.matrixFragShader),
      uniforms: {
        uTextureSize: [256, 128],
        uRainColor: [0.95, 1, 0.95, 1],
        uBackgroundColor: [0, 0.25, 0.05, 1],
        uTime: 0,
        uScale: 10,
        uTrail: 5 + 4 * Math.random(),
        uSpeed: 0.5 + Math.random(),
      },
    });

    const geometry = new PIXI.Geometry()
      .addAttribute('aVertexPosition', [-1, -1, -1, 1, 1, -1, 1, -1, -1, 1, 1, 1])
      .addAttribute('aTextureCoord', [0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1]);

    const mesh = new PIXI.Mesh(geometry, material);
    mesh.position.set(this.pixiApp.view.width / 2, this.pixiApp.view.height / 2);
    mesh.scale.set(window.innerWidth, window.innerHeight)


    const matrixContainer = new PIXI.Container();
    this.pixiApp.stage.addChild(matrixContainer);

    matrixContainer.addChild(mesh);

    this.pepeFilter = new PIXI.Filter("", this.fragShader, this.uniforms );
    this.pepeFilter.enabled = true;

    this.pixiApp.stage.addChild(shaderContainer);

    backGroundGraphics.filters = [ this.pepeFilter ];

    this.pixiApp.ticker.add(() => {
      this.uniforms.u_time += 0.05;
      material.uniforms.uTime = performance.now() * 0.0001;
    });
  }
}
