import {
  Box,
  Button,
  Icon,
  Image,
  ProgressBar,
  Section,
  Stack,
  TimeDisplay,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import '../styles/interfaces/BombImplantDetonator.scss';

type BombData = {
  ref: string;
  name: string;
  rank: string;
  location: string;
  mugshot?: string;
  armed: boolean;
  nuclear: boolean;
  dead: boolean;
  /** Deciseconds remaining until detonation. */
  time_left: number;
  /** Total fuse length in deciseconds, used to scale the radial gauge. */
  fuse_length: number;
  stat_text: string;
  blood_pressure: string;
  blood_oxygen: number;
  pulse: number;
  brute: number;
  burn: number;
  tox: number;
  oxy: number;
  max_health: number;
};

type DetonatorData = {
  bombs: BombData[];
};

export function BombImplantDetonator() {
  const { data } = useBackend<DetonatorData>();
  const { bombs = [] } = data;

  const armedCount = bombs.filter((bomb) => bomb.armed).length;

  return (
    <Window width={620} height={620} theme="contractor">
      <Window.Content scrollable className="DetonatorContent">
        <Stack vertical fill>
          <Stack.Item>
            <Section className="DetonatorHeader">
              <Stack align="center">
                <Stack.Item grow>
                  <Box className="DetonatorHeader__title">
                    Remote Detonation Suite
                  </Box>
                  <Box className="DetonatorHeader__subtitle">
                    Contractor Implant &middot; Secure Uplink
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box className="DetonatorPill">
                    Implants linked: {bombs.length}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box className="DetonatorPill DetonatorPill--danger">
                    Armed: {armedCount}
                  </Box>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            {bombs.length > 0 ? (
              bombs.map((bomb) => <BombCard key={bomb.ref} bomb={bomb} />)
            ) : (
              <DetonatorEmpty />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}

function DetonatorEmpty() {
  return (
    <Section>
      <Box className="DetonatorEmpty">
        <Icon name="bomb" size={4} className="DetonatorEmpty__icon" />
        <Box className="DetonatorEmpty__title">No Implants Linked</Box>
        <Box className="DetonatorEmpty__body">
          No bomb implants are currently registered to this detonation suite.
          Implants are linked automatically when a returned contract target
          qualifies for one.
        </Box>
        <Box className="DetonatorEmpty__hint">
          <Box className="DetonatorEmpty__pulse" />
          Awaiting uplink signal&hellip;
        </Box>
      </Box>
    </Section>
  );
}

function BombCard(props: { bomb: BombData }) {
  const { act } = useBackend();
  const { bomb } = props;

  return (
    <Section
      className={`BombCard ${bomb.armed ? 'BombCard--armed' : ''}`}
      mb={1}
    >
      <Stack>
        {/* Mugshot */}
        <Stack.Item>
          <Box className="BombCard__mug">
            {bomb.mugshot ? (
              <Image
                width="96px"
                height="96px"
                src={`data:image/png;base64,${bomb.mugshot}`}
              />
            ) : (
              <Icon name="user-secret" size={3} />
            )}
          </Box>
        </Stack.Item>

        {/* Identity + vitals */}
        <Stack.Item grow>
          <Box className="BombCard__name">{bomb.name}</Box>
          <Box className="BombCard__rank">{bomb.rank}</Box>
          <Box className="BombCard__loc">
            <Icon name="location-dot" mr={0.5} />
            {bomb.location}
          </Box>

          <Vitals bomb={bomb} />
          <DamageBars bomb={bomb} />
        </Stack.Item>

        {/* Detonation column */}
        <Stack.Item>
          <Detonation bomb={bomb} onArm={() => act('arm', { ref: bomb.ref })} />
        </Stack.Item>
      </Stack>

      {!!bomb.nuclear && (
        <Box className="BombCard__nuke">
          <Icon name="radiation" mr={0.5} />
          <b>FISSILE CORE DETECTED.</b> A plutonium core has been seated in this
          charge &mdash; the blast radius is <b>tripled</b>. Anyone near the
          host when the timer expires will be caught in the fireball.
        </Box>
      )}
    </Section>
  );
}

function Vitals(props: { bomb: BombData }) {
  const { bomb } = props;
  return (
    <Stack mt={1} mb={1}>
      <Stack.Item grow>
        <VitalBox
          label="Blood Pres."
          value={bomb.dead ? '--/--' : bomb.blood_pressure}
        />
      </Stack.Item>
      <Stack.Item grow>
        <VitalBox
          label="Blood Oxy."
          value={bomb.dead ? '--' : `${bomb.blood_oxygen}%`}
          tone={oxygenTone(bomb)}
        />
      </Stack.Item>
      <Stack.Item grow>
        <VitalBox
          label="Pulse"
          value={bomb.dead ? '0' : `${bomb.pulse}`}
          tone={pulseTone(bomb)}
        />
      </Stack.Item>
    </Stack>
  );
}

function VitalBox(props: {
  label: string;
  value: string;
  tone?: 'good' | 'average' | 'bad';
}) {
  const { label, value, tone } = props;
  return (
    <Box className="VitalBox">
      <Box className="VitalBox__label">{label}</Box>
      <Box
        className={`VitalBox__value ${tone ? `VitalBox__value--${tone}` : ''}`}
      >
        {value}
      </Box>
    </Box>
  );
}

function DamageBars(props: { bomb: BombData }) {
  const { bomb } = props;
  const max = bomb.max_health || 100;
  return (
    <Stack vertical>
      <DamageBar label="Brute" value={bomb.brute} max={max} color="#d63b3b" />
      <DamageBar label="Burn" value={bomb.burn} max={max} color="#e7902f" />
      <DamageBar label="Toxin" value={bomb.tox} max={max} color="#5fae3a" />
      <DamageBar label="Oxygen" value={bomb.oxy} max={max} color="#3a8fd1" />
    </Stack>
  );
}

function DamageBar(props: {
  label: string;
  value: number;
  max: number;
  color: string;
}) {
  const { label, value, max, color } = props;
  return (
    <Stack align="center" className="DamageBar">
      <Stack.Item className="DamageBar__label">{label}</Stack.Item>
      <Stack.Item grow>
        <ProgressBar value={value} minValue={0} maxValue={max} color={color}>
          {Math.round(value)}
        </ProgressBar>
      </Stack.Item>
    </Stack>
  );
}

function Detonation(props: { bomb: BombData; onArm: () => void }) {
  const { bomb, onArm } = props;
  const imminent = bomb.armed && bomb.time_left <= 600;
  const fuse = bomb.fuse_length || 1;
  const fraction = bomb.armed
    ? Math.max(0, Math.min(1, bomb.time_left / fuse))
    : 0;
  const sweep = `${fraction * 360}deg`;
  const ringColor = imminent ? 'var(--bomb-bad)' : 'var(--bomb-average)';

  return (
    <Box className="Detonation">
      <Box
        className={`Detonation__ring ${
          bomb.armed ? '' : 'Detonation__ring--idle'
        } ${imminent ? 'Detonation__ring--hot' : ''}`}
        style={{
          background: bomb.armed
            ? `conic-gradient(${ringColor} 0deg ${sweep}, rgba(255, 255, 255, 0.06) ${sweep} 360deg)`
            : undefined,
        }}
      >
        <Box className="Detonation__ringInner">
          <Box className="Detonation__label">Time to Detonation</Box>
          <Box
            className={`Detonation__timer ${
              bomb.armed
                ? imminent
                  ? 'Detonation__timer--hot'
                  : ''
                : 'Detonation__timer--idle'
            }`}
          >
            {bomb.armed ? <TimeDisplay value={bomb.time_left} /> : '--:--'}
          </Box>
          <Box className="Detonation__status">
            {bomb.armed
              ? `\u25CF ${bomb.stat_text}`
              : `\u25CB ${bomb.stat_text}`}
          </Box>
        </Box>
      </Box>

      {!!imminent && (
        <Box className="Detonation__imminent">
          {bomb.nuclear ? 'DOOMSDAY IMMINENT' : 'DETONATION IMMINENT'}
        </Box>
      )}

      {bomb.armed ? (
        <Box className="Detonation__locked">
          Fuse Locked
          <Box className="Detonation__locked-sub">ABORTING NOT POSSIBLE</Box>
        </Box>
      ) : (
        <Button
          fluid
          textAlign="center"
          className="Detonation__arm"
          icon="bomb"
          onClick={onArm}
        >
          Arm Implant
        </Button>
      )}
    </Box>
  );
}

function oxygenTone(bomb: BombData): 'good' | 'average' | 'bad' {
  if (bomb.blood_oxygen >= 95) return 'good';
  if (bomb.blood_oxygen >= 85) return 'average';
  return 'bad';
}

function pulseTone(bomb: BombData): 'good' | 'average' | 'bad' {
  if (bomb.pulse <= 90) return 'good';
  if (bomb.pulse <= 120) return 'average';
  return 'bad';
}
