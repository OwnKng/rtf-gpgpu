import { useMemo, useRef } from "react"
import { GPUComputationRenderer } from "three/examples/jsm/misc/GPUComputationRenderer.js"
import { useFrame, useThree } from "@react-three/fiber"
import * as THREE from "three"

import position from "./shaders/simulation/position.glsl"
import velocity from "./shaders/simulation/velocity.glsl"

import fragment from "./shaders/particles/fragment.glsl"
import vertex from "./shaders/particles/vertex.glsl"

const WIDTH = 256

const maxSpeed = 0.01
const maxForce = 0.25

const createRandomVelocity = (texture: THREE.DataTexture) => {
  const data = texture.image.data

  for (let i = 0; i < data.length; i += 4) {
    data[i + 0] = (Math.random() * 2 - 1) * Math.random()
    data[i + 1] = (Math.random() * 2 - 1) * Math.random()
    data[i + 2] = 0
    data[i + 3] = 0
  }
}

const fillLifeSpanTexture = (width: number) =>
  Float32Array.from(
    new Array(width * width)
      .fill(0)
      .flatMap((_) => [10 + (Math.random() - 0.5) * 5, 0, 0, 0])
  )

const fillPositionTexture = (texture: THREE.DataTexture) => {
  const data = texture.image.data

  for (let i = 0; i < data.length; i += 4) {
    data[i + 0] = 0
    data[i + 1] = 0
    data[i + 2] = 0
    data[i + 3] = 0
  }
}

const Sketch = () => {
  const materialRef = useRef<THREE.ShaderMaterial>(null!)
  const { gl } = useThree()

  const uniforms = useMemo(
    () => ({
      uTime: { value: 0.0 },
      positionTexture: { value: null },
      uMouse: { value: new THREE.Vector3() },
    }),
    []
  )

  const { viewport } = useThree()

  //_ Create the fbo and simulation data
  const [gpuCompute, positionTexture, velocityTexture] = useMemo(() => {
    const gpuRender = new GPUComputationRenderer(WIDTH, WIDTH, gl)

    const dataTexturePosition = gpuRender.createTexture()
    fillPositionTexture(dataTexturePosition)

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

    positionTexture.material.uniforms.uMouse = { value: new THREE.Vector3() }

    positionTexture.wrapS = THREE.RepeatWrapping
    positionTexture.wrapT = THREE.RepeatWrapping
    velocityTexture.wrapS = THREE.RepeatWrapping
    velocityTexture.wrapT = THREE.RepeatWrapping

    gpuRender.init()

    return [gpuRender, positionTexture, velocityTexture]
  }, [gl])

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

    materialRef.current.uniforms.uTime.value = clock.getElapsedTime()

    materialRef.current.uniformsNeedUpdate = true
  })

  return (
    <>
      <mesh
        onPointerMove={(e) => {
          positionTexture.material.uniforms.uMouse.value = e.point
          materialRef.current.uniforms.uMouse.value = e.point
        }}
      >
        <planeGeometry args={[viewport.width, viewport.height]} />
        <meshBasicMaterial transparent opacity={0} />
      </mesh>
      <instancedMesh args={[undefined, undefined, WIDTH * WIDTH]}>
        <boxGeometry args={[0.1, 0.1, 0.1]}>
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
          fragmentShader={fragment}
          blending={THREE.AdditiveBlending}
          transparent={true}
        />
      </instancedMesh>
    </>
  )
}

export default Sketch
