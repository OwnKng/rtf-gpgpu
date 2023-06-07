import { useRef } from "react"
import "./App.css"
import Sketch from "./Sketch"
import { Canvas } from "@react-three/fiber"
import { useThree } from "@react-three/fiber"

function App() {
  return (
    <div className='App'>
      <div className='background' />
      <Canvas
        dpr={1}
        camera={{
          position: [0, 0, 30],
        }}
        shadows
      >
        <ambientLight intensity={0.5} />
        <Lighting />
        <Sketch />
      </Canvas>
    </div>
  )
}

const Lighting = () => {
  const ref = useRef<THREE.PointLight>(null!)
  const { viewport } = useThree()

  return (
    <>
      <pointLight position={[0, 0, 0]} intensity={1.0} ref={ref} />
      <mesh
        onPointerMove={(e) => ref.current.position.copy(e.point)}
        position={[0, 0, 25]}
      >
        <planeGeometry args={[viewport.width, viewport.height, 1, 1]} />
        <meshBasicMaterial transparent opacity={0} />
      </mesh>
    </>
  )
}

export default App
