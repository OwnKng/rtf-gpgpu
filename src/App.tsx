import { OrbitControls } from "@react-three/drei"
import "./App.css"
import Sketch from "./Sketch"
import { Canvas } from "@react-three/fiber"

function App() {
  return (
    <div className='App'>
      <div className='background' />
      <Canvas
        dpr={1}
        camera={{
          position: [0, 5, 20],
        }}
      >
        <ambientLight intensity={0.2} />
        <pointLight position={[0, 10, 5]} intensity={1.0} />
        <OrbitControls />
        <Sketch />
      </Canvas>
    </div>
  )
}

export default App
