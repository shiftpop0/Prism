import { DatabaseOutlined, MenuFoldOutlined, MenuUnfoldOutlined, MessageOutlined, PieChartOutlined, SearchOutlined } from '@ant-design/icons'
import { Breadcrumb, Button, Layout, Menu, Typography } from 'antd'
import { useState } from 'react'
import { Link, Route, Routes, useLocation } from 'react-router-dom'
import DashboardPage from './pages/DashboardPage'
import CluesPage from './pages/CluesPage'
import DialoguePage from './pages/DialoguePage'
import DatabaseViewPage from './pages/DatabaseViewPage'

const { Header, Content, Sider } = Layout
const { Title, Text } = Typography

function App() {
  const location = useLocation()
  const [collapsed, setCollapsed] = useState(false)
  const pageName =
    location.pathname === '/'
      ? '风险总览'
      : location.pathname === '/clues'
        ? '线索工作台'
        : location.pathname === '/dialogue'
          ? '研判助手'
          : location.pathname === '/database'
            ? '数据库管理'
          : 'Prism'

  return (
    <Layout style={{ minHeight: '100vh' }} className="prism-shell">
      <Sider
        width={248}
        theme="light"
        className="prism-sider"
        breakpoint="lg"
        collapsedWidth={72}
        collapsible
        trigger={null}
        collapsed={collapsed}
        onCollapse={setCollapsed}
      >
        <Button
          type="default"
          shape="circle"
          className="sider-edge-toggle"
          icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
          onClick={() => setCollapsed((v) => !v)}
        />
        <div className="prism-logo-wrap">
          <Title level={4} style={{ margin: 0 }} className="prism-logo-title">
            {collapsed ? '棱镜' : '棱镜系统'}
          </Title>
          <Text type="secondary" className={`prism-logo-subtitle${collapsed ? ' is-hidden' : ''}`}>
            风险研判前端原型
          </Text>
        </div>
        <Menu
          mode="inline"
          selectedKeys={[location.pathname]}
          defaultOpenKeys={['main']}
          items={[
            {
              key: 'main',
              label: '个人极端',
              children: [
                { key: '/', icon: <PieChartOutlined />, label: <Link to="/">风险总览</Link> },
                { key: '/clues', icon: <SearchOutlined />, label: <Link to="/clues">线索工作台</Link> },
                { key: '/dialogue', icon: <MessageOutlined />, label: <Link to="/dialogue">研判助手</Link> },
                { key: '/database', icon: <DatabaseOutlined />, label: <Link to="/database">数据库管理</Link> },
              ],
            },
          ]}
        />
      </Sider>

      <Layout>
        <Header className="prism-header">
          <div>
            <Title level={3} style={{ margin: 0 }}>Prism——JZ棱镜风险研判中心</Title>
          </div>
        </Header>
        <Content style={{ margin: 20 }}>
          <Breadcrumb
            style={{ marginBottom: 12 }}
            items={[{ title: 'Prism' }, { title: '个人极端' }, { title: pageName }]}
          />
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/clues" element={<CluesPage />} />
            <Route path="/dialogue" element={<DialoguePage />} />
            <Route path="/database" element={<DatabaseViewPage />} />
          </Routes>
        </Content>
      </Layout>
    </Layout>
  )
}

export default App
