import { useLayoutEffect, useMemo, useRef } from "react"
import { GPUComputationRenderer } from "three/examples/jsm/misc/GPUComputationRenderer.js"
import { useFrame, useThree } from "@react-three/fiber"
import * as THREE from "three"

import position from "./shaders/simulation/position.glsl"
import velocity from "./shaders/simulation/velocity.glsl"

import vertex from "./shaders/particles/vertex.glsl"

const WIDTH = 80

const maxSpeed = 1.0
const maxForce = 0.5

const startingVelocity = new Array(WIDTH * WIDTH)
  .fill(0)
  .flatMap((_) => [
    (Math.random() * 2 - 1) * Math.random(),
    (Math.random() * 2 - 1) * Math.random(),
    0,
    0,
  ])

const createRandomVelocity = (texture: THREE.DataTexture) => {
  const data = texture.image.data

  for (let i = 0; i < data.length; i += 4) {
    data[i + 0] = startingVelocity[i + 0]
    data[i + 1] = startingVelocity[i + 1]
    data[i + 2] = startingVelocity[i + 2]
    data[i + 3] = startingVelocity[i + 3]
  }
}

const fillLifeSpanTexture = (width: number) =>
  Float32Array.from(
    new Array(width * width)
      .fill(0)
      .flatMap((_) => [10 + (Math.random() - 0.5) * 5, maxSpeed, maxForce, 0])
  )

const fillPositionTexture = (
  texture: THREE.DataTexture,
  width: number,
  height: number
) => {
  const data = texture.image.data

  for (let i = 0; i < data.length; i += 4) {
    data[i + 0] = (Math.random() - 0.5) * width
    data[i + 1] = (Math.random() - 0.5) * height
    data[i + 2] = 0
    data[i + 3] = 0
  }
}

const Sketch = () => {
  const materialRef = useRef<THREE.ShaderMaterial>(null!)
  const { gl, viewport } = useThree()

  const uniforms = useMemo(
    () =>
      THREE.UniformsUtils.merge([
        THREE.ShaderLib["phong"].uniforms,
        {
          positionTexture: { value: null },
        },
      ]),
    []
  )

  //_ Create the fbo and simulation data
  const [gpuCompute, positionTexture, velocityTexture] = useMemo(() => {
    const gpuRender = new GPUComputationRenderer(WIDTH, WIDTH, gl)

    const dataTexturePosition = gpuRender.createTexture()
    fillPositionTexture(dataTexturePosition, viewport.width, viewport.height)

    const dataTextureVelocity = gpuRender.createTexture()
    createRandomVelocity(dataTextureVelocity)

    const lifespan = fillLifeSpanTexture(WIDTH)
    const dataTextureLife = new THREE.DataTexture(
      lifespan,
      WIDTH,
      WIDTH,
      THREE.RGBAFormat,
      THREE.FloatType
    )
    dataTextureLife.needsUpdate = true

    const positionTexture = gpuRender.addVariable(
      "texturePosition",
      position,
      dataTexturePosition
    )
    const velocityTexture = gpuRender.addVariable(
      "textureVelocity",
      velocity,
      dataTextureVelocity
    )

    gpuRender.setVariableDependencies(positionTexture, [
      positionTexture,
      velocityTexture,
    ])

    gpuRender.setVariableDependencies(velocityTexture, [
      velocityTexture,
      positionTexture,
    ])

    positionTexture.material.uniforms.uTime = { value: 0.0 }
    velocityTexture.material.uniforms.uTime = { value: 0.0 }
    positionTexture.material.uniforms.delta = { value: 0.0 }
    velocityTexture.material.uniforms.delta = { value: 0.0 }

    positionTexture.material.uniforms.uLifeTexture = { value: dataTextureLife }
    velocityTexture.material.uniforms.uLifeTexture = { value: dataTextureLife }

    // Initial velocity
    const dataTextureInitialVelocity = new THREE.DataTexture(
      Float32Array.from(startingVelocity),
      WIDTH,
      WIDTH,
      THREE.RGBAFormat,
      THREE.FloatType
    )
    dataTextureInitialVelocity.needsUpdate = true
    velocityTexture.material.uniforms.uStartingVelocity = {
      value: dataTextureInitialVelocity,
    }

    velocityTexture.material.uniforms.uMouse = { value: new THREE.Vector3() }

    positionTexture.wrapS = THREE.RepeatWrapping
    positionTexture.wrapT = THREE.RepeatWrapping
    velocityTexture.wrapS = THREE.RepeatWrapping
    velocityTexture.wrapT = THREE.RepeatWrapping

    positionTexture.material.uniforms.uTextureSize = {
      value: new THREE.Vector3(viewport.width, viewport.height, 5),
    }

    gpuRender.init()

    return [gpuRender, positionTexture, velocityTexture]
  }, [gl, viewport])

  // Buffer attributes for the presentational layer
  const [positions, pIndex] = useMemo(
    () => [
      Float32Array.from(new Array(WIDTH * WIDTH * 3).fill(0)),
      Float32Array.from(
        new Array(WIDTH * WIDTH)
          .fill(0)
          .flatMap((_, i) => [
            (i % WIDTH) / WIDTH,
            Math.floor(i / WIDTH) / WIDTH,
          ])
      ),
    ],
    []
  )

  useFrame(({ clock }, delta) => {
    gpuCompute.compute()

    positionTexture.material.uniforms.uTime.value = clock.getElapsedTime()
    velocityTexture.material.uniforms.uTime.value = clock.getElapsedTime()

    positionTexture.material.uniforms.delta.value = delta
    velocityTexture.material.uniforms.delta.value = delta

    materialRef.current.uniforms.positionTexture.value =
      gpuCompute.getCurrentRenderTarget(positionTexture).texture

    materialRef.current.uniformsNeedUpdate = true
  })

  useLayoutEffect(() => {
    const material = materialRef.current

    material.lights = true
    material.color = new THREE.Color(0x42b6f5)
    material.specular = new THREE.Color(0x111111)
    material.shininess = 100

    // Sets the uniforms with the material values
    material.uniforms["diffuse"].value = material.color
    material.uniforms["specular"].value = material.specular
    material.uniforms["shininess"].value = Math.max(material.shininess, 1e-4)
    material.uniforms["opacity"].value = material.opacity

    material.needsUpdate = true

    // Defines
    material.defines.WIDTH = WIDTH.toFixed(1)
    material.defines.BOUNDS = WIDTH.toFixed(1)
  }, [materialRef])

  return (
    <>
      <mesh
        receiveShadow
        onPointerMove={(e) => {
          velocityTexture.material.uniforms.uMouse.value = e.point
        }}
      >
        <planeGeometry args={[viewport.width, viewport.height]} />
        <meshBasicMaterial transparent opacity={0} />
      </mesh>
      <instancedMesh args={[undefined, undefined, WIDTH * WIDTH]}>
        <boxGeometry args={[0.08, 0.08, 0.08]}>
          <instancedBufferAttribute
            attach='attributes-offset'
            array={positions}
            count={positions.length / 3}
            itemSize={3}
          />
          <instancedBufferAttribute
            attach='attributes-pIndex'
            array={pIndex}
            count={pIndex.length / 2}
            itemSize={2}
          />
        </boxGeometry>
        <shaderMaterial
          ref={materialRef}
          uniforms={uniforms}
          vertexShader={vertex}
          fragmentShader={THREE.ShaderChunk["meshphong_frag"]}
          blending={THREE.AdditiveBlending}
        />
      </instancedMesh>
    </>
  )
}

export default Sketch
